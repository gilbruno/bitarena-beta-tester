pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {IBitarenaBetaTester} from "./interfaces/IBitarenaBetaTester.sol";


contract BitarenaBetaTester is ERC721, ERC721Pausable, AccessControl, IBitarenaBetaTester {

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PRIVILEGED_BETA_TESTER_ROLE = keccak256("PRIVILEGED_BETA_TESTER_ROLE");

    uint256 public MINT_PRICE;

    uint256 private _nextTokenId;

    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant MAX_PRIVILEGED_SUPPLY = 10;
    uint256 public constant MAX_REGULAR_SUPPLY = 989;

    uint256 private _privilegedMintCount;

    /// @notice Creates a new BitarenaBetaTester NFT contract
    /// @dev Sets up initial roles and mint price
    constructor()
        ERC721("BitarenaBetaTester", "BITARENABT")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        MINT_PRICE = 0.005 ether;
    }
    
    /// @notice Restricts function access to super admin or default admin
    /// @dev Throws if caller doesn't have either role
    modifier onlySuperAdmin() {
        if (!hasRole(SUPER_ADMIN_ROLE, msg.sender) && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotSuperAdmin();
        }
        _;
    }
    
    /// @notice Pauses the contract
    /// @dev Only callable by pauser role
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract
    /// @dev Only callable by pauser role
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Safely mints a new token
    /// @dev Handles privileged and regular minting
    /// @param to Address to mint the token to
    /// @return tokenId The ID of the newly minted token
    function safeMint(address to) public payable returns (uint256) {
        bool isPrivileged = hasRole(PRIVILEGED_BETA_TESTER_ROLE, msg.sender);
        if (isPrivileged) {
            if (_privilegedMintCount >= MAX_PRIVILEGED_SUPPLY) revert MaxPrivilegedSupplyReached();
            _privilegedMintCount++;
        } else {
            if (msg.value < MINT_PRICE) revert IncorrectMintPrice();
            if (_nextTokenId - _privilegedMintCount >= MAX_REGULAR_SUPPLY) revert MaxRegularSupplyReached();
        }
        
        if (_nextTokenId >= MAX_SUPPLY) revert MaxSupplyReached();
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        emit BitarenaBetaTesterMinted(to, tokenId, isPrivileged);
        return tokenId;
    }

    /// @notice Internal function to update token ownership
    /// @dev Required override to handle pausable functionality
    /// @param to Address to transfer to
    /// @param tokenId Token ID to transfer
    /// @param auth Address authorized to make the transfer
    /// @return Previous owner address
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Pausable)  returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    /// @notice Sets the minter role
    /// @dev Only callable by super admin
    /// @param minter Address to grant minter role to
    function setMinterRole(address minter) public onlySuperAdmin {
        _grantRole(MINTER_ROLE, minter);
    }

    /// @notice Sets the pauser role
    /// @dev Only callable by super admin
     /// @param pauser Address to grant pauser role to
    function setPauserRole(address pauser) public onlySuperAdmin {
        _grantRole(PAUSER_ROLE, pauser);
    }

    /// @notice Sets the mint price
    /// @dev Only callable by super admin
    /// @param mintPrice New mint price in wei
    function setMintPrice(uint256 mintPrice) public onlySuperAdmin {
        uint256 oldPrice = MINT_PRICE;
        MINT_PRICE = mintPrice;
        emit MintPriceUpdated(oldPrice, mintPrice);
    }

    /// @notice Withdraws all ETH from the contract
    /// @dev Only callable by super admin
    /// @return success True if the withdrawal was successful
    function withdraw() external onlySuperAdmin returns (bool success) {
        uint256 balance = address(this).balance;
        (success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) revert WithdrawFailed();
        return success;
    }

    /// @notice Sets the super admin role
    /// @dev Only callable by default admin
    /// @param superAdmin Address to grant super admin role to
    function setSuperAdminRole(address superAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(SUPER_ADMIN_ROLE, superAdmin);
    }

    /// @notice Sets the privileged beta tester role
    /// @dev Only callable by super admin
    /// @param betaTester Address to grant privileged beta tester role to
    function setPrivilegedBetaTesterRole(address betaTester) public onlySuperAdmin {
        _grantRole(PRIVILEGED_BETA_TESTER_ROLE, betaTester);
    }

    /// @notice Supports the ERC721 interface
    /// @dev Required override to support ERC721 interface
    /// @param interfaceId Interface ID to check support for
    /// @return True if the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, IBitarenaBetaTester)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}