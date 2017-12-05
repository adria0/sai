const BigNumber = require("bignumber.js");
const leftPad = require('left-pad')
const dateFormat = require('dateformat');
require('console.table');

const log = v => console.log("------",v,"-------")

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

const DSToken  = artifacts.require("./DSToken.sol");
const DSValue  = artifacts.require("./DSValue.sol");
const SaiVox  = artifacts.require("./SaiVox.sol");
const SaiTap  = artifacts.require("./SaiTap.sol");
const SaiTub  = artifacts.require("./SaiTub.sol");
const SaiTop  = artifacts.require("./SaiTop.sol");
const SaiMom  = artifacts.require("./SaiMom.sol");

timeTravel = seconds => new Promise((resolve, reject) => {
  web3.currentProvider.sendAsync(
      {
          jsonrpc: "2.0",
          method: "evm_increaseTime",
          params: [ seconds ],
          id: new Date().getTime(),
      },
  (err1) => {
      if (err1) return reject(err1);
      web3.currentProvider.sendAsync(
          {
              jsonrpc: "2.0",
              method: "evm_mine",
              params: [],
              id: new Date().getTime(),
          },
      (err2) => {
          if (err2) return reject(err2);
          resolve();
      }
    );
  }
)});

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

	await pip.poke(int2wadhex(1))

	// init system

	var fs = require('fs');
	var data = JSON.parse(fs.readFileSync('test_simulation_1.json', 'utf8'));
	var lastdate = 0
	const matLiquidationRatio = ray2int(await tub.mat())

	var cups = []
	var iterCount = 0

	for (var i = 0; i<data.length; i++) {

		const dateobj = new Date(1000*data[i].date);
		const date = 
			 (100000000*dateobj.getFullYear())
			+(1000000*(1+dateobj.getMonth()))
			+(10000*dateobj.getDate())
			+(100*dateobj.getHours())
			+dateobj.getMinutes()

		const gemPrice = data[i].weightedAverage


		if (date < 201700000000) continue;
//		if (lastdate == date || date < 20170000) continue;
//		lastdate = date

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

		if ( (iterCount++ % (Math.floor(data.length/33))) != 0 ) continue;

		process.stdout.write("\n")

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

		if (cups.length < web3.eth.accounts.length) {

			const acc = web3.eth.accounts[cups.length]

			await gem.mint(acc,int2wad(100))
			await gem.approve(tub.address,int2wad(100) , { from : acc })
			await tub.join(int2wad(100), { from : acc })

			const tx = await tub.open( { from : acc } )

			const cup = txevent(tx,"LogNewCup").cup

			cups.push( { id:cup, killed:"", price: gemPrice, date:date })

			await skr.approve(tub.address, int2wad(100) , { from : acc })
			await tub.lock(cup, int2wad(100), { from : acc })

			let maxSai = Math.round ( ray2int(await tub.tag()) * 100 * (1/matLiquidationRatio))-1
			let sai = Math.round ( maxSai * 0.6 )
			await tub.draw(cup, int2wad(sai), { from : acc })

		}

	}

	callback()

} doit() }

