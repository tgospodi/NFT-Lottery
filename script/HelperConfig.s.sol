// SPDX-License-Identifier: MIT

import {Script} from "../lib/forge-std/src/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        uint256 deployerKey;
    }

    uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            //chain id of sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({entranceFee: 0.1 ether, interval: 1 days, deployerKey: vm.envUint("PRIVATE_KEY")});
    }

    function getOrCreateAnvilEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({entranceFee: 0.1 ether, interval: 1 days, deployerKey: DEFAULT_ANVIL_KEY});
    }
}
