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

	/* run ------------------------------------ */

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
	
	await pip.poke(int2wadhex(1))

	console.log("starting era() = "+dateFormat(1000*(await tub.era())))
	console.log("calling value");
	console.log("starging chi() = "+ray2int(await tub.chi.call()))

	await snapshot("start",acc1)
	await gem.mint(acc1,int2wad(200))
	await snapshot("mint",acc1)

	await gem.approve(tub.address,int2wad(200) , { from : acc1 })
	await tub.join(int2wad(200), { from : acc1 })
	await snapshot("join",acc1)

	// -- open lock & draw cup1

	let tx = await tub.open( { from : acc1 } )
	let cup1 = txevent(tx,"LogNewCup").cup
	await snapshot("open",acc1,cup1)

	await skr.approve(tub.address, int2wad(100) , { from : acc1 })
	await tub.lock(cup1, int2wad(100), { from : acc1})
	await snapshot("lock",acc1,cup1)

	await tub.draw(cup1, int2wad(1), { from : acc1 })
	await snapshot("draw",acc1,cup1)

	dumpsnapshots()

	await sai.approve(tub.address,await sai.INFINITE(), {from:acc1})
	txdumplogs(await tub.shut(cup1, { from : acc1 }))
	await snapshot("shut",acc1)

/*
	await skr.approve(tub.address, int2wad(90) , { from : acc1 })
	await tub.free(cup, int2wad(90), { from : acc1})

	await snapshot("free",acc1,cup)

	await tub.exit(int2wad(90), { from : acc1})

	await snapshot("exit",acc1)
*/
	dumpsnapshots()

	callback()

} doit() } 