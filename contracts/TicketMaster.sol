pragma solidity 0.5.8;

import "./ERC721.sol";
import "./utils/safe-math.sol";
import "./utils/supported-Interfaces.sol";
import "./utils/erc721-token-receiver.sol";
import "./utils/address-utils.sol";

contract TicketMaster is ERC721, SupportsInterface, ERC721TokenReceiver {
    using SafeMath for uint256;
    using AddressUtils for address;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

    mapping(uint256 => address) public idToOwner;
    mapping(uint256 => address) public idToApproval;
    mapping(address => uint256) private ownerToNFTokenCount;
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    uint256 public cap_max;
    string public event_name;
    bool public event_active;
    address public eventOwner;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor(uint256 _cap_max, string memory _event_name) public {
        cap_max = _cap_max;
        event_name = _event_name;
        event_active = true;
        eventOwner = msg.sender;
        supportedInterfaces[_INTERFACE_ID_ERC721] = true;

    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            "NOT OWNER OR OPERATOR"
        );
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            "NOT OWNER APPROVED OR OPERATOR"
        );
        require(event_active == true, "Event is finished");
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(
            idToOwner[_tokenId] != address(0) || _tokenId <= cap_max,
            "NOT VALID TOKEN"
        );
        _;
    }

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool indexed _approved
    );

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

    //========= ERC721  FUNCTIONS =======//

    function balanceOf(address _owner) public view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address _owner;
        _owner = idToOwner[_tokenId];
        require(_owner != address(0), "NO OWNER");
        return _owner;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public payable canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        _safeTransferFrom(_from, _to, _tokenId, "");
        require(
            _checkOnERC721Received(_from, _to, _tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
        public
        payable
        canTransfer(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "NOT OWNER");
        require(_to != address(0), "ZERO ADDRESS");

        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
    {
        address tokenOwner = idToOwner[tokenId];
        require(tokenOwner == msg.sender, "only owner can transfer");
        //solhint-disable-next-line max-line-length
        _transferFrom(from, to, tokenId);
    }

    function approve(address _approved, uint256 _tokenId)
        public
        payable
        canOperate(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner, "IS OWNER");

        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId)
        public
        view
        validNFToken(_tokenId)
        returns (address)
    {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        return ownerToOperators[_owner][_operator];
    }

    //========= onERC721Received INTERFACE =======//

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    //========= CONTRACT FUNCTIONS =======//

    /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
    function BuyTicket(uint256 _tokenId) public payable {
        require(
            idToOwner[_tokenId] == 0x0000000000000000000000000000000000000000,
            "TICKET ALREADY SOLD"
        );
        require(
            msg.value >= 10000,
            "Ticket require payment at least 10000 wei"
        );
        _addNFToken(msg.sender, _tokenId);

        emit Transfer(address(0), msg.sender, _tokenId);
    }

    function eventBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function finishEvent() public {
        require(msg.sender == eventOwner, "Only Event Owner can finish event");
        event_active = false;
    }

    //========= INTERNAL FUNCTIONS =======//

    /**
   * @dev Assignes a new NFT to owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), "NFT_ALREADY_EXISTS");

        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, "NOT_OWNER");
        ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
        delete idToOwner[_tokenId];
    }

    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address _from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(_from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId)
        public
        payable
        canTransfer(_tokenId)
        validNFToken(_tokenId)
    {
        _transfer(_to, _tokenId);
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transferFrom(_from, _to, tokenId);
        require(
            _checkOnERC721Received(_from, _to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(
            abi.encodeWithSelector(
                ERC721TokenReceiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

}
