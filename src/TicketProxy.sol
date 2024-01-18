// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Beacon} from "./Beacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

/**
 * @title TicketProxy
 * @author Todor Gospodinov
 * @notice TicketProxy contract for lottery ticket with beacon proxy approach
 */

contract TicketProxy is BeaconProxy {
    /**
     * @notice Initializer function which acts as constructor for upgradeable contracts.
     * @param _beacon  The address of the beacon contract.
     */
    constructor(address _beacon) BeaconProxy(_beacon, "") {}
}
