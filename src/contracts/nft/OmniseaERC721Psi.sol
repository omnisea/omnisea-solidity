// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IOmniseaERC721Psi.sol";
import "../interfaces/IOmniseaERC721.sol";
import "../interfaces/IOmniseaDropsScheduler.sol";
import "../interfaces/IOmniseaDropsManager.sol";
import {CreateParams, Phase, BasicCollectionParams} from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../ERC721Psi/ERC721Psi.sol";
import "../ERC721Psi/extensions/ERC721PsiAddressData.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OmniseaERC721Psi is IOmniseaERC721Psi, ERC721PsiAddressData, ReentrancyGuard {
    using Strings for uint256;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    // @dev Contract-level Metadata
    string public collectionURI;
    // @dev Token-level Metadata
    string public tokensURI;
    address public override dropsManager;
    bool public isZeroIndexed;
    uint256 public createdAt;
    uint256 public override endTime;
    uint24 public royaltyAmount;
    uint24 public maxSupply;
    // @notice Editions have unlimited supply
    bool public isEdition;
    // @notice non-transferable token (Soulbound Token)
    bool public isSBT;
    address public override owner;
    mapping(address => uint256) public userClaimTime;
    bool private isInitialized;
    bool private isMintedToPlatform;
    IOmniseaDropsScheduler public scheduler;
    address internal immutable _revenueManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    mapping(address => uint256) public userStaked;
    uint256 public totalStaked;
    uint256 public collectedFees;

    function initialize(
        CreateParams memory params,
        address _owner,
        address _dropsManager,
        address _scheduler
    ) external {
        require(!isInitialized);
        _init(params.name, params.symbol);
        isInitialized = true;
        dropsManager = _dropsManager;
        tokensURI = params.tokensURI;
        maxSupply = params.maxSupply;
        collectionURI = params.uri;
        isZeroIndexed = params.isZeroIndexed;
        endTime = params.endTime;
        isEdition = params.isEdition;
        isSBT = params.isSBT;
        _setNextTokenId(isZeroIndexed ? 0 : 1);
        royaltyAmount = params.royaltyAmount;
        owner = _owner;
        scheduler = IOmniseaDropsScheduler(_scheduler);
        createdAt = block.timestamp;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("ipfs://", collectionURI));
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (maxSupply == 0 || isEdition || bytes(tokensURI).length == 0) {
            return contractURI();
        }

        return string(abi.encodePacked("ipfs://", tokensURI, "/", tokenId.toString(), ".json"));
    }

    function mint(address _minter, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external override nonReentrant {
        require(msg.sender == dropsManager);
        require(isAllowed(_minter, _quantity, _merkleProof, _phaseId), "!isAllowed");
        scheduler.increasePhaseMintedCount(_minter, _phaseId, _quantity);
        _mint(_minter, _quantity);
    }

    function mintPrice(uint8 _phaseId) public view override returns (uint256) {
        return scheduler.mintPrice(_phaseId);
    }

    function isAllowed(address _account, uint24 _quantity, bytes32[] memory _merkleProof, uint8 _phaseId) internal view returns (bool) {
        require(block.timestamp < endTime);
        if (maxSupply > 0) require(maxSupply >= (totalMinted() + _quantity));

        return scheduler.isAllowed(_account, _quantity, _merkleProof, _phaseId);
    }

    function setPhase(
        uint8 _phaseId,
        uint256 _from,
        uint256 _to,
        bytes32 _merkleRoot,
        uint24 _maxPerAddress,
        uint256 _price,
        address _token,
        uint256 _minToken
    ) external onlyOwner {
        scheduler.setPhase(_phaseId, _from, _to, _merkleRoot, _maxPerAddress, _price, _token, _minToken);
    }

    function setTokensURI(string memory _uri) external onlyOwner {
        require(block.timestamp < endTime + 14 days);
        tokensURI = _uri;
        emit BatchMetadataUpdate(_startTokenId(), type(uint256).max);
    }

    function setContractURI(string memory _uri) external onlyOwner {
        require(block.timestamp < endTime + 14 days);
        collectionURI = _uri;
    }

    function preMintToTeam(uint256 _quantity) external nonReentrant onlyOwner {
        if (maxSupply > 0) {
            require(maxSupply >= totalMinted() + _quantity);
        } else {
            require(block.timestamp < endTime);
        }
        _mint(owner, _quantity);
    }

    function preMintToPlatform(uint256 _quantity) external {
        require(msg.sender == _revenueManager && !isMintedToPlatform && _quantity <= 5);
        if (maxSupply > 0) {
            require(maxSupply >= totalMinted() + _quantity);
        } else {
            require(block.timestamp < endTime);
        }
        isMintedToPlatform = true;
        _mint(_revenueManager, _quantity);
    }

    function _startTokenId() internal view override returns (uint256) {
        return isZeroIndexed ? 0 : 1;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address _receiver, uint256 _royaltyAmount) {
        _receiver = owner;
        _royaltyAmount = (value * royaltyAmount) / 10000;
    }

    function setRoyaltyAmount(uint24 _royaltyAmount) external onlyOwner {
        royaltyAmount = _royaltyAmount;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(!isSBT, "SBT: transfer not allowed");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(!isSBT, "SBT: transfer not allowed");
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(!isSBT, "SBT: transfer not allowed");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _burn(tokenId);
    }

    // @notice the ability to intervene if a creator set the wrong end time or didn't manage to reveal metadata in time.
    function setEndTime(uint256 _endTime) external {
        require(msg.sender == _revenueManager);
        endTime = _endTime;
    }

    function stake(uint256 _amount) external nonReentrant {
        require(block.timestamp + 120 days >= endTime, "endTime > 4 months");
        require(block.timestamp < endTime, "<endTime");
        uint256 minStake = IOmniseaDropsManager(dropsManager).minStake();
        require(_amount >= minStake, "amount < minStake");
        IERC20 osea = IOmniseaDropsManager(dropsManager).osea();
        require(osea.transferFrom(msg.sender, address(this), _amount), "!transferFrom");
        userStaked[msg.sender] += _amount;
        totalStaked += _amount;

        uint256 daysSinceStart = (block.timestamp - createdAt) / 1 days;
        userClaimTime[msg.sender] = endTime + (daysSinceStart * 1 days);
    }

    function unstakeAndClaim() external nonReentrant {
        uint256 claimTime = userClaimTime[msg.sender];
        require(block.timestamp >= claimTime, "<claimTime");
        uint256 staked = userStaked[msg.sender];
        require(staked > 0, "!staked");
        userStaked[msg.sender] = 0;
        IERC20 osea = IOmniseaDropsManager(dropsManager).osea();
        require(osea.transfer(msg.sender, staked), "!transfer");
        uint256 stakerRewards = (collectedFees * staked) / totalStaked;
        (bool success, ) = msg.sender.call{value: stakerRewards}("");
        require(success, "!success");
    }

    function stakingInfo(address staker) external view returns(uint256, uint256, uint256, uint256) {
        return (totalStaked, userStaked[staker], userClaimTime[staker], collectedFees);
    }

    receive() external payable {
        collectedFees += msg.value;
    }
}
