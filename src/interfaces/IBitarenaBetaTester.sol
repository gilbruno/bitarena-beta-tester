// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IBitarenaBetaTester {

    event BitarenaBetaTesterMinted(address indexed to, uint256 indexed tokenId, bool isPrivileged);
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice);

    error IncorrectMintPrice();
    error MaxPrivilegedSupplyReached();
    error MaxRegularSupplyReached();
    error MaxSupplyReached();
    error WithdrawFailed();
    error NotSuperAdmin();
    error AlreadyMinted();
    function pause() external;
    function unpause() external;

    function safeMint() external payable returns (uint256);

    function getNextTokenId() external view returns (uint256);

    function setSuperAdminRole(address superAdmin) external;
    function setPrivilegedBetaTesterRole(address betaTester) external;
    function setPauserRole(address pauser) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}