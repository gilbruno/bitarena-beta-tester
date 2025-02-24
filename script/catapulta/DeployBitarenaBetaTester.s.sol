//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BitarenaDeploymentKeys} from "./BitarenaDeploymentKeys.sol";
import {BitarenaBetaTester} from "../../src/BitarenaBetaTester.sol";
/**
 * @title Deploy All contracts
 * @author 
 * @notice 
 */
contract DeployBitarenaBetaTester is Script {
  function run() external {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER_BITARENA_NFT_BETA_TESTER");
    vm.startBroadcast(deployerPrivateKey);
    
    // BitarenaChallenge
    /*address superAdmin = BitarenaDeploymentKeys.SUPER_ADMIN_BITARENA_NFT_BETA_TESTER;
    address pauser = BitarenaDeploymentKeys.PAUSER_BITARENA_NFT_BETA_TESTER;*/  


    //******************************************************************/
    // ********** 1 - Deploy BitarenaBetaTester ****************/
    //******************************************************************/
    BitarenaBetaTester bitarenaBetaTester = new BitarenaBetaTester();
    console.log("BitarenaBetaTester deployed to %s", address(bitarenaBetaTester));

    vm.stopBroadcast();

  }
}
