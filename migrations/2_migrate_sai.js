/*
const BigNumber = require("bignumber.js");

const Migrations = artifacts.require("./Migrations.sol");

const DSToken = artifacts.require("./DSToken.sol");
const DSValue = artifacts.require("./DSValue.sol");
const DSAuth  = artifacts.require("./DSAuth.sol");
const SaiVox  = artifacts.require("./SaiVox.sol");
const SaiTap  = artifacts.require("./SaiTap.sol");
const DSGuard = artifacts.require("./DSGuard.sol");
const SaiTub  = artifacts.require("./SaiTub.sol");
const SaiTop  = artifacts.require("./SaiTop.sol");
const SaiMom  = artifacts.require("./SaiMom.sol");
*/
module.exports = function(deployer) {
/*
 	deployer.then( async () => {

 		const gem = await DSToken.new("ETH");
	 	const gov = await DSToken.new("GOV");
	 	const sai = await DSToken.new("SAI");
	 	const sin = await DSToken.new("SIN");
 		const skr = await DSToken.new("SKR")
		const pip = await DSValue.new();
		const pep = await DSValue.new();

		await deployer.deploy(SaiVox)
		const vox = await SaiVox.deployed();

		await deployer.deploy(SaiTap)		
		const tap = await SaiTap.deployed();

		const pit = "0x0000000000000000000000000000000000000123"

		await deployer.deploy(SaiTub,
			sai.address,sin.address,skr.address,gem.address,
			gov.address,pip.address,pep.address,vox.address,
			tap.address,pit
		);
		const tub = await SaiTub.deployed();

		await tap.turn(tub.address)

		await deployer.deploy(SaiTop,
			tub.address,
			tap.address			
		);
		const top = await SaiTop.deployed();

		await deployer.deploy(SaiMom,
			tub.address,
			tap.address,
			vox.address
		);
		const mom = await SaiMom.deployed();

		await deployer.deploy(DSGuard)
		const dad = await DSGuard.deployed();

		await dad.permit(await dad.ANY(),await dad.ANY(),await dad.ANY())

		await vox.setAuthority(dad.address);
		await tub.setAuthority(dad.address);
		await tap.setAuthority(dad.address);
		await top.setAuthority(dad.address);
		await sai.setAuthority(dad.address);
		await sin.setAuthority(dad.address);
		await skr.setAuthority(dad.address);
		await mom.setAuthority(dad.address);

		wad = v => new BigNumber(10).pow(18).mul(v)
		ray = v => new BigNumber(10).pow(27).mul(v)

		await mom.setHat(wad(10000000))
		await mom.setMat(ray(1.35)) // 1.35
		await mom.setAxe(ray(1.00))
		await mom.setTax(ray(1.00))
		await mom.setTapGap(wad(1.00))
		await mom.setTubGap(wad(1.00))
		await mom.setWay(ray(1.0))
		await mom.setFee((10002 * 10 ** 23)-1)
 	})
*/
};
