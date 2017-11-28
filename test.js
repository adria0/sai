const BigNumber = require("bignumber.js");

const DSToken  = artifacts.require("./DSToken.sol");
const SaiVox  = artifacts.require("./SaiVox.sol");
const SaiTap  = artifacts.require("./SaiTap.sol");
const SaiTub  = artifacts.require("./SaiTub.sol");
const SaiTop  = artifacts.require("./SaiTop.sol");
const SaiMom  = artifacts.require("./SaiMom.sol");

module.exports = function(callback) { async function doit()  {

	log = v => console.log("------",v,"-------")

	/* init ------------------------------------ */

	towad = v => new BigNumber(10).pow(18).mul(v)
	fromwad = v => new BigNumber(v).div(  BigNumber(10).pow(18) ).toNumber()
	toray = v => new BigNumber(10).pow(27).mul(v)

	hex2int = v => (new BigNumber(v,16)).toNumber()
	int2hex = v => "0x"+v.toString(16)

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

    const {
        0: owner,
        1: acc1,
        2: acc2,
        3: acc3
    } = web3.eth.accounts;

	/* run ------------------------------------ */

	await gem.mint(acc1,towad(100))

	await gem.approve(tub.address,towad(100) , { from : acc1 })
	await tub.join(towad(100), { from : acc1 })
	let tx = await tub.open( { from : acc1} )
	let cup = tx.logs[0].args.cup

	await skr.approve(tub.address, await skr.balanceOf(acc1) , { from : acc1 })
	log(1111)
	await tub.lock(cup, await skr.balanceOf(acc1), { from : acc1})
	log(222)

	log(await tub.ink(cup))
	await tub.draw(cup, towad(1), { from : acc1 })

	log(1)
	await skr.approve(tub.address, await skr.balanceOf(acc1) , { from : acc1 })
	log(4)
	await tub.free(cup, await sai.balanceOf(acc1), { from : acc1})


	console.log(hex2int(cup))

	/* end ------------------------------------ */

	callback()

} doit() } 
