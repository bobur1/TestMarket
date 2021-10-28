import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, network, waffle } from 'hardhat';
import { expect, assert } from 'chai';
import { BigNumber} from "ethers";

import Web3 from 'web3';
// @ts-ignore
const web3 = new Web3(network.provider) as Web3;

import { NFT, MarketPlace } from '../typechain';
import { Address } from 'cluster';
const provider = waffle.provider;

const depositAmount = ethers.utils.parseEther('1');

let nft0: NFT;
let nft1: NFT;
let marketPlace: MarketPlace;

let owner: SignerWithAddress;
let user0: SignerWithAddress;
let user1: SignerWithAddress;
let user2: SignerWithAddress;
let user3: SignerWithAddress;
let users:Array<SignerWithAddress>;

describe('Contract: MarketPlace', () => {
    beforeEach(async () => {
        [owner, user0, user1, user2, user3, ...users] = await ethers.getSigners();
        const NFT = await ethers.getContractFactory('NFT');
        nft0 = await NFT.deploy() as NFT;
        nft1 = await NFT.deploy() as NFT;
        const MarketPlace = await ethers.getContractFactory('MarketPlace');
        marketPlace = await MarketPlace.deploy() as MarketPlace;

        // add tokens
        await nft0.mintDefaultItems(user0.address, depositAmount);
        await nft1.mintDefaultItems(user1.address, depositAmount);   
    });
    
	describe('Deployment', () => {
		it('Chech Roles in NFTs contract', async () => {
            const minterRole = await nft0.MINTER_ROLE();
			expect(await nft0.hasRole(minterRole, owner.address)).to.equal(true);
			expect(await nft1.hasRole(minterRole, owner.address)).to.equal(true);
		});
        it('Check minting in nfts', async () => {
            // checking default item tokens amount
			expect(await nft0.balanceOf(user0.address, 0)).to.equal(depositAmount);
		});
    });

    describe('Transactions', () => {
        beforeEach(async () => {
            await nft0.connect(user0).setApprovalForAll(marketPlace.address, true);
            // user1 wants to buy nfts to depositAmount
            await marketPlace.connect(user1).offer(nft0.address, 0, depositAmount, 5,
                {
                    value: depositAmount.mul(5)
                }
            );

            // user0 wants to sell nfts to 2*depositAmount
            await marketPlace.connect(user0).listing(nft0.address, 0, depositAmount.mul(2), 5);
        });

        it('Check offer', async () => {
            expect(await provider.getBalance(marketPlace.address)).to.equal(depositAmount.mul(5));
		});

        it('Check listing', async () => {
            await marketPlace.connect(user0).listing(nft0.address, 0, depositAmount.div(2), 2);

            expect(await nft0.balanceOf(user1.address, 0)).to.equal(BigNumber.from(2));
            // user0 sold 2 tokens for user1 price (which is depositAmount) => marketplace balance = 
            expect(await provider.getBalance(marketPlace.address)).to.equal(depositAmount.mul(3));
            expect((await marketPlace.bids(0)).amount).to.equal(BigNumber.from(3));
		});

        it('Add more offers', async () => {
            let marketPlaceBalanceBefore = await provider.getBalance(marketPlace.address);

            await marketPlace.connect(user2).offer(nft0.address, 0, depositAmount.mul(3), 3,
                {
                    value: depositAmount.mul(9)
                }
            );

            expect(await nft0.balanceOf(user2.address, 0)).to.equal(BigNumber.from(3));
            expect((await marketPlace.sales(0)).amount).to.equal(BigNumber.from(2)); 
            expect(await provider.getBalance(marketPlace.address)).to.equal(marketPlaceBalanceBefore);
		});
    });
});
