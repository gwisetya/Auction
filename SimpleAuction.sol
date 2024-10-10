// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract SimpleAuction{
    /*Errors*/
    error SimpleAuction__bidEnded(); 
    error SimpleAuction__belowHighestBid(); 
    error SimpleAuction__noPendingReturns(); 
    error SimpleAuction__bidNotEnded(); 
    error SimpleAuction__AuctionFinalized(); 

    /*Events*/
    event auctionEnded(address indexed winner, uint256 finalBidAmount); 

    /*State Variable*/
    address payable internal beneficiary;
    uint256 internal auctionEndTime; 
    address internal highestBidder; 
    uint256 internal highestBid = 0;
    bool internal auctionFinalized = false; 
    mapping(address => uint256) internal pendingReturns;

    /*Constructor*/
    constructor(address payable _beneficiary, uint256 _auctionDuration){
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _auctionDuration; 
    }

    /*Function*/
    function bid() public payable{
        require(block.timestamp < auctionEndTime, SimpleAuction__bidEnded());
        require(msg.value > highestBid, SimpleAuction__belowHighestBid()); 
        if(highestBid != 0){
            pendingReturns[highestBidder] = highestBid;
        }
        highestBid = msg.value;
        highestBidder = msg.sender; 
    }

    function withdraw() public payable{
        require(pendingReturns[msg.sender] != 0, SimpleAuction__noPendingReturns()); 
        uint256 returnAmount = pendingReturns[msg.sender]; 
        pendingReturns[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: returnAmount}("");
        if(!success){
            pendingReturns[msg.sender] = returnAmount; 
        }
    }

    function auctionEnd() public {
        require(block.timestamp > auctionEndTime, SimpleAuction__bidNotEnded());
        require(!auctionFinalized, SimpleAuction__AuctionFinalized());
        (bool success, ) = payable(beneficiary).call{value: highestBid}("");
        if(success){
            auctionFinalized = true; 
            emit auctionEnded(highestBidder, highestBid);
        }
    }

    /*Getters*/
    function getBeneficiary() public view returns(address payable){
        return beneficiary;
    }

    function getAuctionEndTme() public view returns(uint256){
        return auctionEndTime; 
    }

    function getHighestBidder() public view returns(address){
        return highestBidder;
    }
    function getHighestBid() public view returns(uint256){
        return highestBid;
    }
    
    function getPendingReturns(address _bidder) public view returns(uint256){
        return pendingReturns[_bidder]; 
    }

    function isAuctionFinalized() public view returns(bool){
        return auctionFinalized;
    }
}