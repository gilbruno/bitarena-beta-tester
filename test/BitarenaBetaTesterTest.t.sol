// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BitarenaBetaTester} from "../src/BitarenaBetaTester.sol";
import {IBitarenaBetaTester} from "../src/interfaces/IBitarenaBetaTester.sol";  
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract BitarenaBetaTesterTest is Test {
    BitarenaBetaTester public bitarenaBetaTester;

    address public defaultSuperAdmin = makeAddr("DEFAULT_SUPER_ADMIN");
    address public superAdmin = makeAddr("SUPER_ADMIN");
    address public pauser = makeAddr("PAUSER");
    uint256 public MAX_REGULAR_SUPPLY;
    uint256 public MAX_PRIVILEGED_SUPPLY;
    uint256 public MAX_SUPPLY;
    uint256 public MINT_PRICE;

    function setUp() public {
        vm.startPrank(defaultSuperAdmin);
        bitarenaBetaTester = new BitarenaBetaTester();
        MAX_REGULAR_SUPPLY = bitarenaBetaTester.MAX_REGULAR_SUPPLY();
        MAX_PRIVILEGED_SUPPLY = bitarenaBetaTester.MAX_PRIVILEGED_SUPPLY();
        MAX_SUPPLY = bitarenaBetaTester.MAX_SUPPLY();
        MINT_PRICE = bitarenaBetaTester.MINT_PRICE();
        vm.stopPrank();
    }

    function test_OnlySuperAdminCanSetPauserRole() public {
        // Setup a non-admin account
        address nonAdmin = makeAddr("nonAdmin");
        
        address newPauser = makeAddr("newPauser");

        // Should revert when called by non-admin
        vm.prank(nonAdmin);
        vm.expectRevert(IBitarenaBetaTester.NotSuperAdmin.selector);
        bitarenaBetaTester.setPauserRole(nonAdmin);

        // Should succeed when called by super admin
        vm.prank(defaultSuperAdmin);
        bitarenaBetaTester.setPauserRole(newPauser);
        
        // Verify role was granted
        assertTrue(bitarenaBetaTester.hasRole(bitarenaBetaTester.PAUSER_ROLE(), newPauser));
    }

    function test_OnlySuperAdminCanSetMintPrice() public {
        // Setup a non-admin account and new price
        address nonAdmin = makeAddr("nonAdmin");
        uint256 newPrice = 0.1 ether;
        
        // Should revert when called by non-admin
        vm.prank(nonAdmin);
        vm.expectRevert(IBitarenaBetaTester.NotSuperAdmin.selector);
        bitarenaBetaTester.setMintPrice(newPrice);

        // Should succeed when called by super admin
        vm.prank(defaultSuperAdmin);
        bitarenaBetaTester.setMintPrice(newPrice);
        
        // Verify price was updated
        assertEq(bitarenaBetaTester.MINT_PRICE(), newPrice);
    }

    // Test that only DEFAULT_ADMIN can call setSuperAdminRole
    function test_OnlyDefaultAdminCanSetSuperAdmin() public {
        // Setup a non-admin address
        address nonAdmin = makeAddr("nonAdmin");
        
        // Should revert when called by non-admin
        vm.startPrank(nonAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                nonAdmin,
                bitarenaBetaTester.DEFAULT_ADMIN_ROLE()
            )
        );
        bitarenaBetaTester.setSuperAdminRole(nonAdmin);
        vm.stopPrank();


        // Should succeed when called by default admin
        address newSuperAdmin = makeAddr("newSuperAdmin");
        vm.prank(defaultSuperAdmin); // owner has DEFAULT_ADMIN_ROLE from constructor
        bitarenaBetaTester.setSuperAdminRole(newSuperAdmin);
        
        // Verify role was granted
        assertTrue(bitarenaBetaTester.hasRole(bitarenaBetaTester.SUPER_ADMIN_ROLE(), newSuperAdmin));
    }

    // Test that only DEFAULT_ADMIN can call setPrivilegedBetaTesterRole
    function test_OnlyDefaultAdminCanSetPrivilegedBetaTesterRole() public {
        console.logBytes32(bitarenaBetaTester.DEFAULT_ADMIN_ROLE());


        // Setup a non-admin address
        address nonAdmin = makeAddr("nonAdmin");
        
        // Should revert when called by non-admin
        vm.startPrank(nonAdmin);
        vm.expectRevert(IBitarenaBetaTester.NotSuperAdmin.selector);
        bitarenaBetaTester.setPrivilegedBetaTesterRole(nonAdmin);
        vm.stopPrank();


        // Should succeed when called by default admin
        address newPrivilegedBetaTester = makeAddr("newPrivilegedBetaTester");
        vm.prank(defaultSuperAdmin); // owner has DEFAULT_ADMIN_ROLE from constructor
        bitarenaBetaTester.setPrivilegedBetaTesterRole(newPrivilegedBetaTester);
        
        // Verify role was granted
        assertTrue(bitarenaBetaTester.hasRole(bitarenaBetaTester.PRIVILEGED_BETA_TESTER_ROLE(), newPrivilegedBetaTester));
    }

    function test_CannotExceedMaxRegularSupply() public {
        // Setup regular user
        address regularUser = makeAddr("regularUser");
        // Setup wallets différents pour chaque mint
        address[] memory users = new address[](1000); 
        for(uint i = 0; i < users.length; i++) {
            users[i] = address(uint160(i + 1000)); // Offset pour éviter les adresses basses
            vm.deal(users[i], 1 ether);
        }

        // Mint MAX_REGULAR_SUPPLY tokens
        for (uint256 i = 0; i < MAX_REGULAR_SUPPLY; i++) {
            vm.startPrank(users[i]);
            bitarenaBetaTester.safeMint{value: MINT_PRICE}();
            vm.stopPrank();
        }

        console.log("MAX_REGULAR_SUPPLY:", MAX_REGULAR_SUPPLY);
        console.log("getNextTokenId:", bitarenaBetaTester.getNextTokenId());

        console.logBytes4(IBitarenaBetaTester.MaxRegularSupplyReached.selector);
        console.logBytes4(bytes4(keccak256("MaxRegularSupplyReached()")));

        // Try to mint one more - should revert
        vm.deal(regularUser, 1 ether);
        vm.expectRevert(IBitarenaBetaTester.MaxRegularSupplyReached.selector);
        vm.startPrank(regularUser);
        bitarenaBetaTester.safeMint{value: 1 ether}();
        vm.stopPrank();

        // Capture le revert avec le bon msg.value
        // (bool success, bytes memory data) = address(bitarenaBetaTester).call{
        //     value: MINT_PRICE
        // }(
        //     abi.encodeWithSelector(
        //         bitarenaBetaTester.safeMint.selector
        //     )
        // );
        // console.log("Actual revert data:");
        // console.logBytes(data);
        // Verify total supply
        assertEq(bitarenaBetaTester.getNextTokenId(), MAX_REGULAR_SUPPLY+1);
    }

    function test_LogTokenIdBeforeAndAfterMint() public {
        // Setup regular user
        address user = makeAddr("user");
        vm.deal(user, 1 ether);
        
        // Log before mint
        console.log("NextTokenId before mint:", bitarenaBetaTester.getNextTokenId());
        
        // Mint a token
        vm.startPrank(user);
        bitarenaBetaTester.safeMint{value: MINT_PRICE}();
        vm.stopPrank();
        // Log after mint
        console.log("NextTokenId after mint:", bitarenaBetaTester.getNextTokenId());
    }


    function test_ShowSelectors() public pure {
        bytes4 actualRevert = 0x71e296a0;
        bytes4 computed = bytes4(keccak256("MaxRegularSupplyReached()"));
        
        console.log("Actual revert:   ");
        console.logBytes4(actualRevert);
        console.log("Computed selector:");
        console.logBytes4(computed);
    }


    function testContractBalance() public {
        // Setup
        uint256 mintPrice = 0.005 ether;
        uint256 expectedBalance = 0;
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        vm.prank(user1);
        bitarenaBetaTester.safeMint{value: mintPrice}();
        expectedBalance += mintPrice;
        
        vm.prank(user2);
        bitarenaBetaTester.safeMint{value: mintPrice}();
        expectedBalance += mintPrice;
        
        // Vérifie la balance du contrat
        assertEq(address(bitarenaBetaTester).balance, expectedBalance);
        
        // Vérifie qu'un privileged user ne paie pas
        vm.prank(defaultSuperAdmin);
        bitarenaBetaTester.setPrivilegedBetaTesterRole(user3);
        
        vm.prank(user3);
        bitarenaBetaTester.safeMint();
        
        // La balance ne doit pas changer
        assertEq(address(bitarenaBetaTester).balance, expectedBalance);
    }

    function testTokenIdOwnership() public {
        // Setup
        uint256 mintPrice = 0.005 ether;
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        // Premier mint avec user1
        vm.prank(user1);
        uint256 tokenId1 = bitarenaBetaTester.safeMint{value: mintPrice}();
        
        // Deuxième mint avec user2  
        vm.prank(user2);
        uint256 tokenId2 = bitarenaBetaTester.safeMint{value: mintPrice}();
        
        // Vérifications
        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertEq(bitarenaBetaTester.ownerOf(1), user1);
        assertEq(bitarenaBetaTester.ownerOf(2), user2);
    }

    function testCannotMintWhenPaused() public {
        // Setup
        uint256 mintPrice = 0.005 ether;
        address user1 = makeAddr("user1");
        vm.deal(user1, 1 ether);
        
        // Pause le contrat
        vm.prank(defaultSuperAdmin);
        bitarenaBetaTester.pause();
        
        // Essaie de mint
        vm.prank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        bitarenaBetaTester.safeMint{value: mintPrice}();
        
        // Vérifie qu'aucun token n'a été minté
        assertEq(bitarenaBetaTester.getNextTokenId(), 1);

         // Unpause le contrat
        vm.prank(defaultSuperAdmin);
        bitarenaBetaTester.unpause();

        // Vérifie qu'on peut minter après unpause
        vm.prank(user1);
        bitarenaBetaTester.safeMint{value: mintPrice}();
        
        // Vérifie que le mint a réussi
        assertEq(bitarenaBetaTester.getNextTokenId(), 2);
        assertEq(bitarenaBetaTester.ownerOf(1), user1);
    }


    function testMaxPrivilegedMints() public {
        // Setup 11 privileged users
        address[] memory privUsers = new address[](11);
        for(uint i = 0; i < 11; i++) {
            privUsers[i] = address(uint160(i + 100));
            vm.prank(defaultSuperAdmin);
            bitarenaBetaTester.setPrivilegedBetaTesterRole(privUsers[i]);
        }
        
        // Mint 10 NFTs avec les privileged users
        for(uint i = 0; i < 10; i++) {
            vm.prank(privUsers[i]);
            bitarenaBetaTester.safeMint();
        }
        
        // Le 11ème mint doit échouer
        vm.prank(privUsers[10]);
        vm.expectRevert(IBitarenaBetaTester.MaxPrivilegedSupplyReached.selector);
        bitarenaBetaTester.safeMint();
        
        // Vérifications
        assertEq(bitarenaBetaTester.getNextTokenId(), 11); // 10 tokens mintés
        for(uint i = 0; i < 10; i++) {
            assertEq(bitarenaBetaTester.ownerOf(i + 1), privUsers[i]);
        }
    }

    function testOnlySuperAdminCanWithdraw() public {
        // Setup
        uint256 mintPrice = 0.005 ether;
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        
        // Quelques mints pour avoir une balance
        vm.prank(user1);
        bitarenaBetaTester.safeMint{value: mintPrice}();
        vm.prank(user2);
        bitarenaBetaTester.safeMint{value: mintPrice}();
        
        uint256 contractBalance = address(bitarenaBetaTester).balance;
        assertEq(contractBalance, mintPrice * 2);
        
        // Test que user random ne peut pas withdraw
        vm.prank(user1);
        vm.expectRevert(IBitarenaBetaTester.NotSuperAdmin.selector);
        bitarenaBetaTester.withdraw();
        
        // Setup super admin
        vm.prank(defaultSuperAdmin);
        bitarenaBetaTester.setSuperAdminRole(superAdmin);
        
        // Capture la balance initiale du super admin
        uint256 initialSuperAdminBalance = address(superAdmin).balance;
        
        // Withdraw avec super admin
        vm.prank(superAdmin);
        bool success = bitarenaBetaTester.withdraw();
        
        // Vérifications
        assertTrue(success);
        assertEq(address(bitarenaBetaTester).balance, 0);
        assertEq(address(superAdmin).balance, initialSuperAdminBalance + contractBalance);
    }

    function test_ExactSupplyLimits() public {
        address regularUser = makeAddr("regularUser");
        // Setup regular users
        address[] memory regularUsers = new address[](MAX_REGULAR_SUPPLY+1); // MAX_REGULAR_SUPPLY + 1
        for(uint i = 0; i < regularUsers.length; i++) {
            regularUsers[i] = address(uint160(i + 1000));
            vm.deal(regularUsers[i], 0.1 ether);
        }

        // Setup privileged users
        address[] memory privUsers = new address[](MAX_PRIVILEGED_SUPPLY + 1);
        for(uint i = 0; i < privUsers.length; i++) {
            privUsers[i] = address(uint160(i + 2000));
            vm.startPrank(defaultSuperAdmin);
            bitarenaBetaTester.setPrivilegedBetaTesterRole(privUsers[i]);
            vm.stopPrank();
        }

        // Mint avec les utilisateurs privilégiés (10 max)
        for(uint i = 0; i < MAX_PRIVILEGED_SUPPLY; i++) {
            vm.startPrank(privUsers[i]);
            bitarenaBetaTester.safeMint();
            vm.stopPrank();
        }

        // Vérifie que le 11ème privilegié ne peut pas minter
        vm.startPrank(privUsers[10]);
        vm.expectRevert(IBitarenaBetaTester.MaxPrivilegedSupplyReached.selector);
        bitarenaBetaTester.safeMint();
        vm.stopPrank();
        // Mint avec les utilisateurs réguliers (989 max)
        for(uint i = 0; i < MAX_REGULAR_SUPPLY; i++) {
            vm.startPrank(regularUsers[i]);
            bitarenaBetaTester.safeMint{value: MINT_PRICE}();
            vm.stopPrank();
        }

        // Vérifie que le 990ème régulier ne peut pas minter
        vm.deal(regularUser, 1 ether);
        vm.startPrank(regularUser);
        vm.expectRevert(IBitarenaBetaTester.MaxRegularSupplyReached.selector);
        bitarenaBetaTester.safeMint{value: MINT_PRICE}();
        vm.stopPrank();

        // Vérifications finales
        assertEq(bitarenaBetaTester.getNextTokenId(), MAX_SUPPLY+1);
    }

    function test_MintPriceUpdate() public {
        // Setup initial values
        uint256 initialPrice = 0.05 ether;
        uint256 newPrice = 0.5 ether;
        
        // Set initial price
        vm.prank(defaultSuperAdmin);
        bitarenaBetaTester.setMintPrice(initialPrice);
        
        // First user mints with initial price
        address user1 = makeAddr("user1");
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bitarenaBetaTester.safeMint{value: initialPrice}();
        
        // Super admin updates price
        vm.prank(defaultSuperAdmin);
        bitarenaBetaTester.setMintPrice(newPrice);
        
        // Second user tries to mint with old price
        address user2 = makeAddr("user2");
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        vm.expectRevert(IBitarenaBetaTester.IncorrectMintPrice.selector);
        bitarenaBetaTester.safeMint{value: initialPrice}();
        
        // Verify price was updated
        assertEq(bitarenaBetaTester.MINT_PRICE(), newPrice);
    }

    function test_SupportsInterface() public view {
        // Interface IDs
        bytes4 iERC721 = 0x80ac58cd;        // ERC721
        bytes4 iERC721Metadata = 0x5b5e139f; // ERC721Metadata
        
        // Vérification des interfaces supportées
        assertTrue(bitarenaBetaTester.supportsInterface(iERC721));
        assertTrue(bitarenaBetaTester.supportsInterface(iERC721Metadata));
        
    }


}
