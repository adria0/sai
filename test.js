const BigNumber = require("bignumber.js");
const leftPad = require('left-pad')

require('console.table');

const DSToken  = artifacts.require("./DSToken.sol");
const DSValue  = artifacts.require("./DSValue.sol");
const SaiVox  = artifacts.require("./SaiVox.sol");
const SaiTap  = artifacts.require("./SaiTap.sol");
const SaiTub  = artifacts.require("./SaiTub.sol");
const SaiTop  = artifacts.require("./SaiTop.sol");
const SaiMom  = artifacts.require("./SaiMom.sol");

/*

Note: patch 
// We have BN. Convert it to BigNumber
if (val && val.constructor.isBN) {
copy.args[key] = C.web3.toBigNumber("0x" + val.toString(16));
}

in /usr/local/lib/node_modules/truffle/build/cli.bundled.js:317993
*/

module.exports = function(callback) { async function doit()  {

	log = v => console.log("------",v,"-------")

	/* init ------------------------------------ */

	const WAD = new BigNumber(10).pow(18)
	const RAY = new BigNumber(10).pow(27)

	const int2wad = v => WAD.mul(v)
	const int2ray = v => RAY.mul(v)

	const wad2int = v => v.div(WAD).toNumber()
	const ray2int = v => v.div(RAY).toNumber()

	const int2wadhex = v => "0x"+leftPad(int2wad(v).toString(16),64,0)
	const int2rayhex = v => "0x"+leftPad(int2ray(v).toString(16),64,0)

	const wadhex2int = v => new BigNumber(v,16).div(WAD).toNumber()
	const rayhex2int = v => new BigNumber(v,16).div(RAY).toNumber()
	const inthex2int = v => new BigNumber(v,16).toNumber()

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

	const txevent = (tx,v) => (tx.logs.filter(e=>e.event==v))[0].args

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
		let cupstr = ""
		let cupink = ""
		let cuptab = ""

		if (cup === undefined ) {
			cupstr = "-"
		} else {
			cupstr = inthex2int(cup)			
			cupink = wad2int(await tub.ink(cup))
			let tx = await tub.tab(cup)
			cuptab = wad2int(txevent(tx,"LogReturn").value)
		}

		snapshots.push(
			[op,acc.substr(2,7),gembalance,skrbalance,saibalance,cupstr,cupink,cuptab]
		)

	} 

	dumpsnapshots = () => {
		console.table(
			['op','acc','gem','skr','sai','cup','ink (cup skr)','tab (cup sia)'],
			snapshots
		)
	}

	await snapshot("start",acc1)
	await pip.poke(int2wadhex(1))
	await gem.mint(acc1,int2wad(100))
	await snapshot("mint",acc1)

	await gem.approve(tub.address,int2wad(100) , { from : acc1 })

	await tub.join(int2wad(100), { from : acc1 })
	let tx = await tub.open( { from : acc1 } )
	let cup = txevent(tx,"LogNewCup").cup
	await snapshot("join",acc1,cup)

	await skr.approve(tub.address, await skr.balanceOf(acc1) , { from : acc1 })
	await tub.lock(cup, await skr.balanceOf(acc1), { from : acc1})
	await snapshot("lock",acc1,cup)

	await tub.draw(cup, int2wad(1), { from : acc1 })
	await snapshot("draw",acc1,cup)

	await skr.approve(tub.address, int2wad(90) , { from : acc1 })
	await tub.free(cup, int2wad(90), { from : acc1})

	await snapshot("free",acc1,cup)

	await tub.exit(int2wad(90), { from : acc1})

	await snapshot("exit",acc1)

	dumpsnapshots()

	/* end ------------------------------------ */

	callback()

} doit() } 
