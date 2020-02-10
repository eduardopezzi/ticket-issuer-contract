pragma solidity 0.5.8;

import "./ERC165.sol";

/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is ERC165 {
    /**
   * @dev Mapping of supported intefraces.
   * @notice You must not set element 0xffffffff to true.
   */
    mapping(bytes4 => bool) internal supportedInterfaces;

    bytes4 private InterfaceID_ERC165 = bytes4(
        keccak256("supportsInterface(bytes4)")
    );

    /**
   * @dev Contract constructor.
   */
    constructor() public {
        supportedInterfaces[InterfaceID_ERC165] = true;

    }

    /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   * @return True if _interfaceID is supported, false otherwise.
   */
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

}
