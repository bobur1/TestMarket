import { MarketPlace, NFT } from '../typechain'
import { ethers } from 'hardhat'

async function deployMarketPlace() {
	const NFT = await ethers.getContractFactory('NFT')
	console.log('starting deploying nft...')
	const nft = await NFT.deploy() as NFT
	console.log('NFT deployed with address: ' + nft.address)

	const MarketPlace = await ethers.getContractFactory('MarketPlace')
	console.log('starting deploying MarketPlace...')
	const marketPlace = await MarketPlace.deploy() as MarketPlace
	console.log('MarketPlace deployed with address: ' + marketPlace.address)
}

deployMarketPlace()
.then(() => process.exit(0))
.catch(error => {
	console.error(error)
	process.exit(1)
})
