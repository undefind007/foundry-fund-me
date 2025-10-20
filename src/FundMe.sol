// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {console} from "forge-std/console.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINUSD = 1 * 1e18;
    address[] private s_funderes;
    mapping(address funder => uint256 fundAmount) private s_addressToAmountFund;

    address private immutable i_onwer;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_onwer = msg.sender;
    }

    function fund() public payable {
        console.log("msg.sender inside FundMe.fund(): ", msg.sender);
        require(
            msg.value.getConversionRate(s_priceFeed) > MINUSD,
            "didn't send enough ETH!"
        );
        s_funderes.push(msg.sender);
        s_addressToAmountFund[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < s_funderes.length; i++) {
            address funder = s_funderes[i];
            s_addressToAmountFund[funder] = 0; //reset the funder's fund amount
        }

        //reset array
        s_funderes = new address[](0);

        (bool isSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(isSuccess, "call failure");
    }

    function withdrawCheaper() public onlyOwner {
        uint256 s_funderesLength = s_funderes.length; // only read once from storage, can saving gass
        for (uint256 i = 0; i < s_funderesLength; i++) {
            address funder = s_funderes[i];
            s_addressToAmountFund[funder] = 0; //reset the funder's fund amount
        }

        //reset array
        s_funderes = new address[](0);

        (bool isSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(isSuccess, "call failure");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_onwer, "you don't have permission to do this!");
        if (msg.sender != i_onwer) {
            revert NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getVersion() public view returns (uint256) {
        // Address 0x694AA1769357215DE4FAC081bf1f309aDC325306 //sepolia
        // Address 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF //zksync
        return s_priceFeed.version();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFund[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funderes[index];
    }

    function getOwner() external view returns (address) {
        return i_onwer;
    }
}
