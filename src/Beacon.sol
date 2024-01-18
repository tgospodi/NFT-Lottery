// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title Beacon
 * @author Todor Gospodinov
 * @notice Beacon contract for lottery ticket with beacon proxy approach
 */
contract Beacon is UpgradeableBeacon {
    /**
     * @notice Initializer function which acts as constructor for upgradeable contracts.
     * @param _implementation  The address of the implementation contract.
     */
    constructor(address _implementation, address _owner) UpgradeableBeacon(_implementation, _owner) {}
}
