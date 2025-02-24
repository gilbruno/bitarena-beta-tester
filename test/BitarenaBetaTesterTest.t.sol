// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BitarenaBetaTester} from "../src/BitarenaBetaTester.sol";

contract BitarenaBetaTesterTest is Test {
    BitarenaBetaTester public bitarenaBetaTester;

    address public superAdmin = makeAddr("SUPER_ADMIN");
    address public pauser = makeAddr("PAUSER");

    function setUp() public {
        bitarenaBetaTester = new BitarenaBetaTester();
    }

}
