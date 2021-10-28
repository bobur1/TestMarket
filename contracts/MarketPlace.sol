// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract MarketPlace {
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
    }
    
    function getCurrentBids(address _address) public view returns(Order[] memory) {
        Order[] memory specifiedBids = new Order[](bids.length);
        uint256 bidCounter;
        
        for(uint256 i; i < bids.length; i++) {
            if(bids[i].nft == _address) {
                specifiedBids[bidCounter] = bids[i];
                
                bidCounter++;
            }
        }

        return specifiedBids;
    }
    
    function getCurrentSales(address _address) public view returns(Order[] memory) {
        Order[] memory specifiedSales = new Order[](sales.length);
        uint256 salesCounter;
        
        for(uint256 i; i < sales.length; i++) {
            if(sales[i].nft == _address) {
                specifiedSales[salesCounter] = sales[i];
                
                salesCounter++;
            }
        }

        return specifiedSales;
    }
    
    /**
    * Buy
    **/
    function offer(IERC1155 _nft, uint256 _tokensId, uint256 _price, uint256 _amount) external payable {
       require(_amount > 0, "Token amount should be more than zero");
       require(_price > 0, "Price should be more than zero");
       require(_price * _amount == msg.value, "The price should be equal to ether which has been sent");

       for(uint256 i; i < sales.length; i++) {
            if(sales[i].nft == address(_nft)  && _price >= sales[i].price) {
                if(sales[i].amount > _amount) {
                    sales[i].amount -= _amount;
                    _nft.safeTransferFrom(sales[i].recipient, msg.sender, sales[i].tokensId, _amount, "");
                    (bool sent,) = sales[i].recipient.call{value: (sales[i].price * _amount)}("");
                    require(sent, "Failed to send Ether");
                    // refund
                    if(_price > sales[i].price) {
                        (bool sent1,) = msg.sender.call{value: ((_price - sales[i].price) * _amount)}("");
                        require(sent1, "Failed to send Ether");
                    }
                    _amount = 0;
                } else {
                    _amount -= sales[i].amount;
                    _nft.safeTransferFrom(sales[i].recipient, msg.sender, sales[i].tokensId, sales[i].amount, "");
                    (bool sent,) = sales[i].recipient.call{value: (sales[i].price * sales[i].amount)}("");
                    require(sent, "Failed to send Ether");
                    if(_price > sales[i].price) {
                        (bool sent1,) = msg.sender.call{value: ((_price - sales[i].price) * sales[i].amount)}("");
                        require(sent1, "Failed to send Ether");
                    }
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
    function listing(IERC1155 _nft, uint256 _tokensId, uint256 _price, uint256 _amount) external {
      require(_amount > 0, "Token amount should be more than zero");
      require(_price > 0, "Price should be more than zero");

      for(uint256 i; i < bids.length; i++) {
            if(bids[i].nft == address(_nft)  && _price <= bids[i].price) {
                if(bids[i].amount > _amount) {
                  bids[i].amount -= _amount;
                  _nft.safeTransferFrom(msg.sender, bids[i].recipient, bids[i].tokensId, _amount, "");
                    (bool sent,) = msg.sender.call{value: (bids[i].price * _amount)}("");
                    require(sent, "Failed to send Ether");
                  _amount = 0;
                } else {
                    _amount -= bids[i].amount;
                    _nft.safeTransferFrom(msg.sender, bids[i].recipient, bids[i].tokensId, bids[i].amount, "");
                    (bool sent,) = msg.sender.call{value: (bids[i].price * bids[i].amount)}("");
                    require(sent, "Failed to send Ether");
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
}