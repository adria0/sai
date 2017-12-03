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

/*

Note: patch 
// We have BN. Convert it to BigNumber
if (val && val.constructor.isBN) {
copy.args[key] = C.web3.toBigNumber("0x" + val.toString(16));
}

in /usr/local/lib/node_modules/truffle/build/cli.bundled.js:317993
*/

module.exports = function(callback) { async function doit()  {

	/* init ------------------------------------ */

	const vox = await SaiVox.deployed()
	const tap = await SaiTap.deployed()
	const tub = await SaiTub.deployed()
	const top = await SaiTop.deployed()
	const mom = await SaiMom.deployed()

	const sai = DSToken.at(await tub.sai())
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

	let snapshots = [] 
	snapshot = async (op,acc,cup) => {

		console.log("snapshot",op)

		let gembalance = wad2int(await gem.balanceOf(acc))
		let skrbalance = wad2int(await skr.balanceOf(acc))
		let saibalance = wad2int(await sai.balanceOf(acc))
		
		let chi = ray2int(await tub.chi.call())
		let per = wad2int(await tub.per())
		let cupid = ""
		let cupink = ""
		let cuptab = ""

		if (cup !== undefined ) {
			cupid = inthex2int(cup)	
			cupink = wad2int(await tub.ink(cup))
			cuptab = wad2int(await tub.tab.call(cup))
		}

		let globals = chi + "/" + per

		snapshots.push(
			[op,acc.substr(2,7),gembalance,skrbalance,saibalance,globals,cupid,cupink,cuptab]
		)
	} 

	dumpsnapshots = () => {
		console.log("ink=skr amount | tab = sia w/o chi-norm ")
		console.table(
			['op','acc','gem','skr','sai','chi/per','cup','cupink','cuptab'],
			snapshots
		)
		snapshots = []
	}
	
	/* run ------------------------------------ */

	await pip.poke(int2wadhex(1))

	console.log("starting era() = "+dateFormat(1000*(await tub.era())))
	console.log("starging chi() = "+ray2int(await tub.chi.call()))

	// init system


	var fs = require('fs');
	var data = JSON.parse(fs.readFileSync('simulation.json', 'utf8'));
	var lastdate = 0

	var cups = []
	for (var i = 0; i<data.length; i++) {

		const dateobj = new Date(1000*data[i].date);
		const date = 10000*dateobj.getFullYear()+100+dateobj.getMonth()+dateobj.getDay()
		const gemPrice = data[i].weightedAverage

		if (lastdate == date) continue;

		await pip.poke(int2wadhex(gemPrice))

		if (cups.length < web3.eth.accounts.length) {

			console.log("New cup @ ",date)

			const acc = web3.eth.accounts[cups.length]

			await gem.mint(acc,int2wad(1000))
			await gem.approve(tub.address,int2wad(1000) , { from : acc })
			await tub.join(int2wad(1000), { from : acc })

			const tx = await tub.open( { from : acc } )
			const cup = txevent(tx,"LogNewCup").cup

			cups.push(cups)

			await skr.approve(tub.address, int2wad(1000) , { from : acc })
			await tub.lock(cup, int2wad(1000), { from : acc })

			await tub.draw(cup, int2wad(900), { from : acc })

		}

		lastdate = date

	}

	callback()

} doit() } 