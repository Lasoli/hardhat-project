// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SpaceRiders is ERC1155, Ownable, Pausable, ERC1155Supply {
    uint256 public maxSupply = 100;
    bool public whiteListActive = false; //whitelist allows you to mint for a much lower price
    // uint256[] public maxSupply = [10, 100, 200]; // in order to have different maxSupply per id, later call index in function
    // uint256[] public price = [0.01 ether, 0.001 ether, 0.002 ether]; 

    //give us a way to activate and deactivate the whitelist
    //store whitelist data which is just a text file (careful to call apis in smart contract cause it causes high gas fees), img would be stored on ipfs
    mapping (address => bool) public whiteList; 
    //check if you're on the whitelist

    constructor()
        ERC1155("ipfs://QmT1UAGuiLK2TbpN7ujf1PoNz2RLafyMnAxJF9iYjeEZKg/")
    {}

    //set the whitelist active
    function setWhiteListActive(bool _whiteListActive) public onlyOwner {
        whiteListActive = _whiteListActive; //like setState in ReactJS
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint256 id, uint256 amount) // what token id you want to mint and how many of them ('bytes memory data' would be for external payload stuff, can be removed)
        public payable {
        // onlyOwner removed 
        //check if whitelist is active
        //apply a require rule if whitelist is active
        if (whiteListActive) {
            require(whiteList[msg.sender], "Not on the whitelist!"); // checking mapping --> boolean true or false
        }
        require(totalSupply(id) + amount <= maxSupply, "Sorry, this is it, the cap has been reached!"); //have to add 'id' to totalSupply since every token can have different supply
        require(msg.value >= 0.01 ether * amount, "Not enough ETH sent: check price."); //checking if right amount was supplied, otherwise throw error
        _mint(msg.sender, id, amount, ""); //'data' can be removed as well but empty strings have to be added!
    } //mint is a function in ERC1155 that checks ownership amount

/**
    * @notice adds addresses into a whitelist
    * @param addresses an array of addresses to add to whitelist
    */
    function setWhiteList(address[] calldata addresses ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whiteList[addresses[i]] = true;
        }
    }

    // Add function to withdraw money from contract --> Balance: xy ether
    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }   

    /**
    * @notice returns the metadata uri for a given id
    * @param _id the NFT to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")); //attached to our json file --> overrides the uri function from erc1155 contract
    }


    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}