// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./NFT.sol";

contract MarketPlace is AccessControl{
    struct Order {
      uint256 amount;
      uint256 price;
      uint256 tokensId;
      address recipient;
      address nft;
    }

    Order[] public sales;
    Order[] public bids;
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function getCurrentBids(address _address) public returns(Order[] memory) {
        return _getBids(_address, 0);
    }
    
    function getCurrentSales(address _address) public returns(Order[] memory) {
        return _getSales(_address, 0);
    }
    
    /**
    * Buy
    **/
    function offer(ERC1155 _nft, uint256 _tokensId, uint256 _price, uint256 _amount) external payable {
       require(_amount > 0, "Token amount should be more than zero");
       require(_price > 0, "Price should be more than zero");
       require(_price == msg.value, "The price should be equal to ether which has been sent");

       for(uint256 i; i < sales.length; i++) {
            if(sales[i].nft == address(_nft)  && _price <= sales[i].price) {
                if(sales[i].amount > _amount) {
                    sales[i].amount -= _amount;
                    _nft.safeTransferFrom(sales[i].recipient, msg.sender, sales[i].tokensId, _amount, "");
                    (bool sent,) = address(this).call{value: (sales[i].price * _amount)}("");
                    require(sent, "Failed to send Ether");
                    _amount = 0;
                } else {
                    _amount -= sales[i].amount;
                    _nft.safeTransferFrom(sales[i].recipient, msg.sender, sales[i].tokensId, sales[i].amount, "");
                    (bool sent,) = address(this).call{value: (sales[i].price * sales[i].amount)}("");
                    require(sent, "Failed to send Ether");
                    // pop sales
                    delete sales[i];
                }
            }
            
            if(_amount == 0) {
                break;
            }
        }
        
        if(_amount != 0) {
            bids.push(Order(
                _amount,
                _price,
                _tokensId,
                msg.sender,
                address(_nft)
                ));
        }
    }
    
    /**
    * Sale
    **/ 
    function listing(ERC1155 _nft, uint256 _tokensId, uint256 _price, uint256 _amount) external {
      require(_amount > 0, "Token amount should be more than zero");
      require(_price > 0, "Price should be more than zero");

      for(uint256 i; i < bids.length; i++) {
            if(bids[i].nft == address(_nft)  && _price >= bids[i].price) {
                if(bids[i].amount > _amount) {
                  bids[i].amount -= _amount;
                  _nft.safeTransferFrom(msg.sender, bids[i].recipient, bids[i].tokensId, _amount, "");
                    (bool sent,) = address(this).call{value: (sales[i].price * _amount)}("");
                    require(sent, "Failed to send Ether");
                  _amount = 0;
                } else {
                    _amount -= bids[i].amount;
                    // pop sales
                    delete bids[i];
                }
            }
            
            if(_amount == 0) {
                break;
            }
        }
        
        if(_amount != 0) {
            sales.push(Order(
                _amount,
                _price,
                _tokensId,
                msg.sender,
                address(_nft)
                ));
        }
    }
    
    function _getBids(address _address, uint256 _price) internal view returns(Order[] memory) {
        Order[] memory specifiedBids = new Order[](bids.length);
        uint256 bidCounter;
        
        for(uint256 i; i < bids.length; i++) {
            if(bids[i].nft == _address && (_price == 0 || _price >= bids[i].price)) {
                specifiedBids[bidCounter] = bids[i];
                
                bidCounter++;
            }
        }

        return specifiedBids;
    }
    
    function _getSales(address _address, uint256 _price) internal view returns(Order[] memory) {
        Order[] memory specifiedSales = new Order[](sales.length);
        uint256 salesCounter;
        
        for(uint256 i; i < sales.length; i++) {
            if(sales[i].nft == _address  && (_price == 0 || _price <= sales[i].price)) {
                specifiedSales[salesCounter] = sales[i];
                
                salesCounter++;
            }
        }

        return specifiedSales;
    }
}