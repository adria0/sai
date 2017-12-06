const BigNumber = require("bignumber.js");
const leftPad = require('left-pad')
const dateFormat = require('dateformat');
require('console.table');

const WAD = new BigNumber(10).pow(18)
const RAY = new BigNumber(10).pow(27)

const int2wad    = v => WAD.mul(v)
const int2ray    = v => RAY.mul(v)
const wad2int    = v => v.div(WAD).toNumber()
const ray2int    = v => v.div(RAY).toNumber()
const int2wadhex = v => "0x"+leftPad(int2wad(v).toString(16),64,0)
const int2rayhex = v => "0x"+leftPad(int2ray(v).toString(16),64,0)
const wadhex2int = v => new BigNumber(v,16).div(WAD).toNumber()
const rayhex2int = v => new BigNumber(v,16).div(RAY).toNumber()
const inthex2int = v => new BigNumber(v,16).toNumber()

const txevent = (tx,v) => (tx.logs.filter(e=>e.event==v))[0].args
const txdumplogs = (tx) => (tx.logs.filter(e=>e.event=="Log")).forEach(e=>console.log("LOG:"+e.args.what+"="+e.args.value))

const DSToken = artifacts.require("./DSToken.sol");
const DSValue = artifacts.require("./DSValue.sol");
const SaiVox = artifacts.require("./SaiVox.sol");
const SaiTap = artifacts.require("./SaiTap.sol");
const SaiTub = artifacts.require("./SaiTub.sol");
const SaiTop = artifacts.require("./SaiTop.sol");
const SaiMom = artifacts.require("./SaiMom.sol");

const MAX_CUPS = 20
const AMOUNT = 100
const MAT_LIQUIDATION_RATIO = 1.35

const SAI_RISK = 2.2
const STEPS = 1
const FILE = 'test_simulation_2017.csv'

module.exports = function(callback) { async function doit()  {

	/* init ------------------------------------ */

	const vox = await SaiVox.deployed()
	const tap = await SaiTap.deployed()
	const tub = await SaiTub.deployed()
	const top = await SaiTop.deployed()
	const mom = await SaiMom.deployed()

	const sin = DSToken.at(await tub.sin())
	const skr = DSToken.at(await tub.skr())
	const gem = DSToken.at(await tub.gem())
	const gov = DSToken.at(await tub.gov())

	const pip = DSValue.at(await tub.pip())

    const {
        0: owner,
        1: acc1,
        2: acc2,
        3: acc3
    } = web3.eth.accounts;
	
	/* run ------------------------------------ */

	await mom.setMat(int2ray(MAT_LIQUIDATION_RATIO))
	await pip.poke(int2wadhex(1))

	// init system
	var fs = require('fs');
	var data = fs
		.readFileSync(FILE, 'utf8')
		.split("\n")
		.map(x=>x.split(","));

	var cups = []
	let lastCheck = -data.length

	for (var i = 0; i<data.length; i+=STEPS) {

		const date = data[i][0]
		const gemPrice = parseFloat(data[i][1])

		await pip.poke(int2wadhex(gemPrice))

		process.stdout.write("*")
		
		for (let cupno = 0; cupno<cups.length; cupno++) {
			if (cups[cupno].killed=="") {
				const cupid = cups[cupno].id
				const cupsafe = await tub.safe.call(cupid)
				if (!cupsafe) {
					cups[cupno].killed = date +" "+gemPrice
					process.stdout.write("K")
				}
			}
		}

		if ( (i - lastCheck) < (data.length/MAX_CUPS) ) continue;

		lastCheck = i

		process.stdout.write("\n")
		console.log("Pending count=",data.length-i)

		/// --- create cup

		if (cups.length < MAX_CUPS) {

			const acc = web3.eth.accounts[cups.length]

			await gem.mint(acc,int2wad(AMOUNT))
			await gem.approve(tub.address,int2wad(AMOUNT) , { from : acc })
			await tub.join(int2wad(AMOUNT), { from : acc })

			const tx = await tub.open( { from : acc } )

			const cup = txevent(tx,"LogNewCup").cup

			cups.push( { id:cup, killed:"", price: gemPrice, date:date })

			await skr.approve(tub.address, int2wad(AMOUNT) , { from : acc })
			await tub.lock(cup, int2wad(AMOUNT), { from : acc })

			let sai = Math.round ( ray2int(await tub.tag()) * AMOUNT * (1/SAI_RISK))

			await tub.draw(cup, int2wad(sai), { from : acc })

		}

		/// --- dump cup contents

		let safeCups = 0
		let cupInfos = []
		let totalKilled = 0
		for (let cupno = 0; cupno<cups.length; cupno++) {
			const cupid = cups[cupno].id
			cupInfos.push([
				inthex2int(cupid),
				cups[cupno].date,
				cups[cupno].price,
				cups[cupno].killed
			])
			if (cups[cupno].killed!="") {
				totalKilled++;
			}
		}

		cupInfos.push(['total','','',Math.round(100*totalKilled/cups.length,2)+"%"]);

		console.table(
			['cupid','date','price','killed'],
			cupInfos
		)

	}

	callback()

} doit() }

