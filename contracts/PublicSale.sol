// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PublicSale is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Mi Primer Token
    // Crear su setter
    IERC20 miPrimerToken;

    // 21 de diciembre del 2022 GMT
    uint256 constant startDate = 1671580800;

    // Maximo price NFT
    uint256 constant MAX_PRICE_NFT = 50000 * 10 ** 18;

    // Gnosis Safe
    // Crear su setter
    address gnosisSafeWallet;

    mapping(uint256 => bool) nftSold;

    event DeliverNft(address winnerAccount, uint256 nftId);
    event TestEvent(bool test);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function setMiPrimerToken(address _address) public {
        miPrimerToken = IERC20(_address);
    }
    //0x32FFa8C3E0E98Db3D04E3ADfC0553E25a11dbD8e
    function setGnosisSafeWallet(address _address) public {
        gnosisSafeWallet = _address;
    }

    function _testEvent() public {
        emit TestEvent(true);
    }

    function purchaseNftById(uint256 _id) external {
        // Realizar 3 validaciones:
        // 1 - el id no se haya vendido. Sugerencia: llevar la cuenta de ids vendidos
        //         * Mensaje de error: "Public Sale: id not available"
        // 2 - el msg.sender haya dado allowance a este contrato en suficiente de MPRTKN
        //         * Mensaje de error: "Public Sale: Not enough allowance"
        // 3 - el msg.sender tenga el balance suficiente de MPRTKN
        //         * Mensaje de error: "Public Sale: Not enough token balance"
        // 4 - el _id se encuentre entre 1 y 30
        //         * Mensaje de error: "NFT: Token id out of range"

        require(!nftSold[_id], "Public Sale: id not available");
        require(_id >= 1 && _id <= 30, "NFT: Token id out of range");

        // // Obtener el precio segun el id
        uint256 priceNft = _getPriceById(_id) * (10 ** 18);
        //100000000000000000000
        // emit TestEvent(address(miPrimerToken) == address(0));

        require(miPrimerToken.allowance(msg.sender, address(this)) >= priceNft, "Public Sale: Not enough allowance");
        require(miPrimerToken.balanceOf(msg.sender) >= priceNft, "Public Sale: Not enough token balance");

        // // Purchase fees
        // // 10% para Gnosis Safe (fee)
        uint256 fee = (priceNft * 10) / 100;
        // // 90% se quedan en este contrato (net)
        uint256 net = priceNft - fee;
        // // from: msg.sender - to: gnosisSafeWallet - amount: fee
        miPrimerToken.transferFrom(msg.sender, gnosisSafeWallet, fee);
        // // from: msg.sender - to: address(this) - amount: net
        miPrimerToken.transferFrom(msg.sender, address(this), net);

        addNFTToSaleList(_id);

        // EMITIR EVENTO para que lo escuche OPEN ZEPPELIN DEFENDER
        emit DeliverNft(msg.sender, _id);
    }

    function addNFTToSaleList(uint256 id) public {
        nftSold[id] = true;
    }

    function depositEthForARandomNft() public payable {
        // Realizar 2 validaciones
        // 1 - que el msg.value sea mayor o igual a 0.01 ether
        require(msg.value >= 0.01 ether, "Monto de ether insuficiente");
        // 2 - que haya NFTs disponibles para hacer el random
        // Escgoer una id random de la lista de ids disponibles
        (uint256 nftId, uint256 length) = _getRandomNftId();
        require(length > 0, "NFTs no disponibles");

        // gnosisSafeWallet.call();

        // Enviar ether a Gnosis Safe
        // SUGERENCIA: Usar gnosisSafeWallet.call para enviar el ether
        // Validar los valores de retorno de 'call' para saber si se envio el ether correctamente
        (bool success, ) = gnosisSafeWallet.call{value: 0.01 ether, gas: 500000}("");
        require(success, "No se pudo realizar la operacion");

        // Dar el cambio al usuario
        // El vuelto seria equivalente a: msg.value - 0.01 ether
        if (msg.value > 0.01 ether) {
            // logica para dar cambio
            // usar '.transfer' para enviar ether de vuelta al usuario
            uint256 returnEthers = msg.value - 0.01 ether;
            payable(msg.sender).transfer(returnEthers);
        }

        addNFTToSaleList(nftId);

        // EMITIR EVENTO para que lo escuche OPEN ZEPPELIN DEFENDER
        emit DeliverNft(msg.sender, nftId);
    }

    // PENDING
    // Crear el metodo receive

    ////////////////////////////////////////////////////////////////////////
    /////////                    Helper Methods                    /////////
    ////////////////////////////////////////////////////////////////////////

    // Devuelve un id random de NFT de una lista de ids disponibles
    function _getRandomNftId() public view returns (uint256, uint256) {
        (uint256[] memory list, uint256 length) = getEnableNFts();
        uint256 randomIndex = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
                length);
        return (list[randomIndex], length);
    }

    function getEnableNFts() public view returns(uint256[] memory, uint256) {
        uint256[] memory enableNFTs = new uint[](30);
        uint256 currentIndex = 0;
        for(uint256 i = 0; i < 30; i++) {
            if(!nftSold[i]) {
                enableNFTs[currentIndex] = i;
                currentIndex++;
            }
        }
        return (enableNFTs, currentIndex);
    }

    // Según el id del NFT, devuelve el precio. Existen 3 grupos de precios
    function _getPriceById(uint256 _id) internal pure returns (uint256) {
        uint256 priceGroupOne = 10;
        uint256 priceGroupTwo = 20;
        uint256 priceGroupThree = 30;
        if (_id > 0 && _id < 11) {
            return priceGroupOne;
        } else if (_id > 10 && _id < 21) {
            return priceGroupTwo;
        } else {
            return priceGroupThree;
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}
