// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MintParams} from "../structs/erc721/ERC721Structs.sol";
import "../interfaces/IOmniseaERC721Psi.sol";
import "../interfaces/IOmniseaDropsFactory.sol";
import "../interfaces/IOmniseaDropsManager.sol";

contract OmniseaDropsManager is IOmniseaDropsManager, ReentrancyGuard {
    event Minted(address collection, address minter, uint256 quantity, uint256 value);

    uint256 public fixedFee;
    uint256 public dynamicFee;
    uint256 public communityFee;
    address private _revenueManager;
    address private _owner;
    bool private _isPaused;
    IOmniseaDropsFactory private _factory;
    // OSEA Drop-Staking
    IERC20 public override osea;
    uint256 public override minStake = 10000 * 10**18;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address factory_) {
        _owner = msg.sender;
        _revenueManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        _factory = IOmniseaDropsFactory(factory_);
        dynamicFee = 0;
        fixedFee = 150000000000000;
        communityFee = 50000000000000;
    }

    function setDynamicFee(uint256 fee_) external onlyOwner {
        require(fee_ <= 20);
        dynamicFee = fee_;
    }

    function setFixedFee(uint256 fee_) external onlyOwner {
        fixedFee = fee_;
    }

    function setCommunityFee(uint256 fee_) external onlyOwner {
        communityFee = fee_;
    }

    function setRevenueManager(address _manager) external onlyOwner {
        _revenueManager = _manager;
    }

    function setOsea(IERC20 _osea, uint256 _minStake) external onlyOwner {
        osea = _osea;
        minStake = _minStake;
    }

    function mint(MintParams calldata _params) external payable nonReentrant {
        require(!_isPaused);
        require(_factory.drops(_params.collection));
        address recipient = _params.to;
        uint8 phaseId = _params.phaseId;
        address collectionAddress = _params.collection;
        uint24 quantity = _params.quantity;
        IOmniseaERC721Psi collection = IOmniseaERC721Psi(collectionAddress);


        uint256 price = collection.mintPrice(phaseId);
        uint256 quantityPrice = price * quantity;
        require(msg.value == quantityPrice + fixedFee + communityFee, "!=price");

        if (quantityPrice > 0) {
            uint256 paidToOwner = quantityPrice * (100 - dynamicFee) / 100;
            (bool p1,) = payable(collection.owner()).call{value: paidToOwner}("");
            require(p1, "!p1");

            (bool p2,) = payable(_revenueManager).call{value: msg.value - paidToOwner - communityFee}("");
            require(p2, "!p2");
        } else {
            (bool p3,) = payable(_revenueManager).call{value: msg.value - communityFee}("");
            require(p3, "!p3");
        }

        if (communityFee > 0) {
            (bool p4,) = payable(collectionAddress).call{value: communityFee}("");
            require(p4, "!p4");
        }

        collection.mint(recipient, quantity, _params.merkleProof, phaseId);
        emit Minted(collectionAddress, recipient, quantity, msg.value);
    }

    function setPause(bool isPaused_) external onlyOwner {
        _isPaused = isPaused_;
    }

    function withdraw() external onlyOwner {
        (bool p,) = payable(_owner).call{value: address(this).balance}("");
        require(p, "!p");
    }

    receive() external payable {}
}
