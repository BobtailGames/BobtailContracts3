/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { MatchManager, MatchManagerInterface } from "../MatchManager";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_mainSigner",
        type: "address",
      },
      {
        internalType: "address",
        name: "_bbone",
        type: "address",
      },
      {
        internalType: "address",
        name: "_flappyAvax",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "matchDuration",
        type: "uint256",
      },
    ],
    name: "MatchDurationUpdated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "maxPlayersPerMatch",
        type: "uint256",
      },
    ],
    name: "MaxPlayersPerMatchUpdated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "player",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "matchId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "NewAddressInMatch",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "matchId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "slot",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "duration",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "maxPlayers",
        type: "uint256",
      },
    ],
    name: "NewMatch",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256[]",
        name: "portionRewardPerRank",
        type: "uint256[]",
      },
    ],
    name: "PortionRewardPerRankUpdated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "player",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "matchIds",
        type: "uint256[]",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "reward",
        type: "uint256",
      },
    ],
    name: "RewardClaimed",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "matchDuration",
        type: "address",
      },
    ],
    name: "StakingManagerUpdated",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_region",
        type: "string",
      },
    ],
    name: "activeMatchsCount",
    outputs: [
      {
        internalType: "uint256",
        name: "count",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "allowedNftContract",
    outputs: [
      {
        internalType: "contract IBobtailNFT",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "bbone",
    outputs: [
      {
        internalType: "contract IBBone",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256[]",
        name: "_matchIds",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "_ranks",
        type: "uint256[]",
      },
      {
        internalType: "bytes32",
        name: "r",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "s",
        type: "bytes32",
      },
      {
        internalType: "uint8",
        name: "v",
        type: "uint8",
      },
    ],
    name: "claimReward",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "currentMatchForAddress",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "currentMatchForToken",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_tokenId",
        type: "uint256",
      },
      {
        internalType: "string",
        name: "region",
        type: "string",
      },
    ],
    name: "joinMatch",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "lastMatchIdClaimedForAccount",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "mainSigner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "matchCountPerRegion",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "matchDuration",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_address",
        type: "address",
      },
    ],
    name: "matchForAddress",
    outputs: [
      {
        internalType: "uint256",
        name: "matchId",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "finished",
        type: "bool",
      },
      {
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "duration",
        type: "uint256",
      },
      {
        internalType: "bool",
        name: "inMatch",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "matchIdCounter",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    name: "matchs",
    outputs: [
      {
        internalType: "bool",
        name: "started",
        type: "bool",
      },
      {
        internalType: "bool",
        name: "finished",
        type: "bool",
      },
      {
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "duration",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "maxPlayers",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "slot",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "maxPlayersPerMatch",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    name: "serverRegions",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_matchDuration",
        type: "uint256",
      },
    ],
    name: "setMatchDuration",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_matchCountPerRegion",
        type: "uint256",
      },
    ],
    name: "setMatchsPerRegion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_maxPlayersPerMatch",
        type: "uint256",
      },
    ],
    name: "setMaxPlayersPerMatch",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256[]",
        name: "_portionRewardPerRank",
        type: "uint256[]",
      },
    ],
    name: "setPortionRewardPerRank",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_name",
        type: "string",
      },
      {
        internalType: "bool",
        name: "status",
        type: "bool",
      },
    ],
    name: "setServerRegion",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_stakingManager",
        type: "address",
      },
    ],
    name: "setStakingManager",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "stakingManager",
    outputs: [
      {
        internalType: "contract IBobtailStaking",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_tokenId",
        type: "uint256",
      },
    ],
    name: "tokenInMatch",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalRewardPerMatch",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x60c06040526001600055610151600355610258600655606460075560026008553480156200002c57600080fd5b5060405162002a4c38038062002a4c8339810160408190526200004f9162000297565b6200005a3362000228565b600480546001600160a01b0319166001600160a01b0394851617905560408051614e4160f01b81526009600282018190529151908190036022019020805460ff1916600117905591831660805290911660a05260056020526108987f05b8ccbb9d4d8fb16ea74ce3c29a41f1b461fbdaff4714a0d9a8eb05499746bc556105147f1471eb6eb2c5e789fc3de43f8ce62938c7d1836ec861730447e2ada8fd81017b556102bc7f89832631fb3c3307a103ba2c84ab569c64d6182a18893dcd163f0f1c2090733a556101f47fa9bc9a3a348c357ba16b37005d7e6b3236198c0e939f4af8c5f19b8deeb8ebc05561012c7f3eec716f11ba9e820c81ca75eb978ffb45831ef8b7a53e5e422c26008e1ca6d55560fa7f458b30c2d72bfd2c6317304a4594ecbafe5f729d3111b65fdc3a33bd48e5432d5560c87f069400f22b28c6c362558d92f66163cec5671cba50b61abd2eecfcd0eaeac5185560647feddb6698d7c569ff62ff64f1f1492bf14a54594835ba0faac91f84b4f5d814605560327ffb33122aa9f93cc639ebe80a7bc4784c11e6053dde89c6f4f7e268c6a623da1e5560005260197fc0a4a8be475dfebc377ebef2d7c4ff47656f572a08dd92b81017efcdba0febe155620002e1565b600180546001600160a01b038381166001600160a01b0319831681179093556040519116919082907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e090600090a35050565b80516001600160a01b03811681146200029257600080fd5b919050565b600080600060608486031215620002ad57600080fd5b620002b8846200027a565b9250620002c8602085016200027a565b9150620002d8604085016200027a565b90509250925092565b60805160a051612737620003156000396000818161047f01526117bc0152600081816103170152610c1301526127376000f3fe608060405234801561001057600080fd5b50600436106101c45760003560e01c80636d5e8f28116100f9578063bbcacf0311610097578063e6c4070e11610071578063e6c4070e1461047a578063f2fde38b146104a1578063f7cd08c1146104b4578063ff9bb409146104c757600080fd5b8063bbcacf0314610430578063be8b4e1514610439578063dade62021461046757600080fd5b80638a09f036116100d35780638a09f036146103d95780638da5cb5b146103ec578063b00bba6a146103fd578063bb626fde1461041057600080fd5b80636d5e8f28146103a5578063715018a6146103ae578063885a5021146103b657600080fd5b806337bc01e1116101665780634f1e353f116101405780634f1e353f146103395780634fdc2fb41461034c57806359d04f1f146103555780635f9862831461036857600080fd5b806337bc01e1146102ec578063474fa01f146102ff578063476b6d921461031257600080fd5b806317c4ecfb116101a257806317c4ecfb1461021a57806322828cc21461028e5780632401e4e6146102b957806328dd99d0146102cc57600080fd5b80630200c069146101c95780630d83ed4b146101de5780630e649a0b14610211575b600080fd5b6101dc6101d7366004612207565b6104d0565b005b6101fe6101ec3660046122b9565b600f6020526000908152604090205481565b6040519081526020015b60405180910390f35b6101fe60065481565b61025f6102283660046122d6565b600c602052600090815260409020805460018201546002830154600384015460049094015460ff8085169561010090950416939086565b6040805196151587529415156020870152938501929092526060840152608083015260a082015260c001610208565b6002546102a1906001600160a01b031681565b6040516001600160a01b039091168152602001610208565b6101dc6102c736600461233f565b610cc6565b6101fe6102da3660046122b9565b600d6020526000908152604090205481565b6101dc6102fa366004612396565b610cfe565b6101dc61030d3660046122d6565b61142d565b6102a17f000000000000000000000000000000000000000000000000000000000000000081565b6101fe6103473660046123d8565b611482565b6101fe600b5481565b6101dc6103633660046122d6565b6114f0565b61037b6103763660046122b9565b6115a7565b6040805195865293151560208601529284019190915260608301521515608082015260a001610208565b6101fe60085481565b6101dc611601565b6103c96103c43660046122d6565b611637565b6040519015158152602001610208565b6101dc6103e736600461240e565b611665565b6001546001600160a01b03166102a1565b6101dc61040b3660046122b9565b611c22565b6101fe61041e3660046122d6565b600e6020526000908152604090205481565b6101fe60035481565b6103c9610447366004612470565b805160208183018101805160098252928201919093012091525460ff1681565b6004546102a1906001600160a01b031681565b6102a17f000000000000000000000000000000000000000000000000000000000000000081565b6101dc6104af3660046122b9565b611c9a565b6101dc6104c23660046122d6565b611d35565b6101fe60075481565b6000546001146105145760405162461bcd60e51b815260206004820152600a6024820152695245454e5452414e435960b01b60448201526064015b60405180910390fd5b6002600055851580159061052757508315155b6105655760405162461bcd60e51b815260206004820152600f60248201526e125b9d985b1a59081c995c5d595cdd608a1b604482015260640161050b565b8584146105a65760405162461bcd60e51b815260206004820152600f60248201526e125b9d985b1a59081c995c5d595cdd608a1b604482015260640161050b565b60008787878733306040516020016105c396959493929190612557565b60405160208183030381529060405280519060200120905060008160405160200161061a91907f19457468657265756d205369676e6564204d6573736167653a0a3332000000008152601c810191909152603c0190565b60408051808303601f1901815282825280516020918201206004546000855291840180845281905260ff87169284019290925260608301889052608083018790529092506001600160a01b03169060019060a0016020604051602081039080840390855afa158015610690573d6000803e3d6000fd5b505050602060405103516001600160a01b0316146106e25760405162461bcd60e51b815260206004820152600f60248201526e57726f6e67207369676e617475726560881b604482015260640161050b565b6000805b89811015610bf05760008b8b83818110610702576107026125a5565b90506020020135116107495760405162461bcd60e51b815260206004820152601060248201526f13585d18da081a59081a5b9d985b1a5960821b604482015260640161050b565b600089898381811061075d5761075d6125a5565b9050602002013511801561078957506065898983818110610780576107806125a5565b90506020020135105b6107c45760405162461bcd60e51b815260206004820152600c60248201526b14985b9ac81a5b9d985b1a5960a21b604482015260640161050b565b600c60008c8c848181106107da576107da6125a5565b90506020020135815260200190815260200160002060010154600014156108395760405162461bcd60e51b815260206004820152601360248201527213585d18da081a5cdb89dd081cdd185c9d1959606a1b604482015260640161050b565b61085a8b8b8381811061084e5761084e6125a5565b90506020020135611de4565b1561089f5760405162461bcd60e51b815260206004820152601560248201527413585d18da081a5cc81b9bdd08199a5b9a5cda1959605a1b604482015260640161050b565b600c60008c8c848181106108b5576108b56125a5565b60209081029290920135835250818101929092526040908101600090812033825260060190925290205460ff166109255760405162461bcd60e51b8152602060048201526014602482015273082c8c8e4cae6e640dcdee840d2dc40dac2e8c6d60631b604482015260640161050b565b600c60008c8c8481811061093b5761093b6125a5565b602090810292909201358352508181019290925260409081016000908120338252600601909252902054610100900460ff16156109ba5760405162461bcd60e51b815260206004820181905260248201527f4163636f756e7420616e64206d617463682072657761726420636c61696d6564604482015260640161050b565b600c60008c8c848181106109d0576109d06125a5565b90506020020135815260200190815260200160002060070160008a8a848181106109fc576109fc6125a5565b90506020020135815260200190815260200160002054600014610a615760405162461bcd60e51b815260206004820152601c60248201527f52616e6b2072657761726420686173206265656e20636c61696d656400000000604482015260640161050b565b6000610a848a8a84818110610a7857610a786125a5565b90506020020135611e0e565b90506001600c60008e8e86818110610a9e57610a9e6125a5565b602090810292909201358352508181019290925260409081016000908120338252600601909252812080549215156101000261ff001990931692909217909155600190600c908e8e86818110610af657610af66125a5565b90506020020135815260200190815260200160002060070160008c8c86818110610b2257610b226125a5565b9050602002013581526020019081526020016000208190555080600c60008e8e86818110610b5257610b526125a5565b602090810292909201358352508181019290925260409081016000908120338252600601909252902060020155898983818110610b9157610b916125a5565b90506020020135600c60008e8e86818110610bae57610bae6125a5565b602090810292909201358352508181019290925260409081016000908120338252600601909252902060010155610be581846125d1565b9250506001016106e6565b508015610cb557604051634a0a0e4b60e01b8152336004820152602481018290527f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031690634a0a0e4b90604401600060405180830381600087803b158015610c5f57600080fd5b505af1158015610c73573d6000803e3d6000fd5b505050507fde44805992b70ab499033e37a0bb5830acec04de9ed6d99e81d48e67cf454bad338b8b84604051610cac94939291906125e9565b60405180910390a15b505060016000555050505050505050565b8060098484604051610cd992919061261f565b908152604051908190036020019020805491151560ff19909216919091179055505050565b6001546001600160a01b03163314610d285760405162461bcd60e51b815260040161050b9061262f565b600a8114610d785760405162461bcd60e51b815260206004820152601c60248201527f4c656e677468206f662061727261792073686f756c6420626520313000000000604482015260640161050b565b600082826009818110610d8d57610d8d6125a5565b90506020020135600a610da09190612664565b83836008818110610db357610db36125a5565b90506020020135600a610dc69190612664565b84846007818110610dd957610dd96125a5565b90506020020135600a610dec9190612664565b85856006818110610dff57610dff6125a5565b90506020020135600a610e129190612664565b86866005818110610e2557610e256125a5565b905060200201356005610e389190612664565b87876004818110610e4b57610e4b6125a5565b9050602002013588886003818110610e6557610e656125a5565b9050602002013589896002818110610e7f57610e7f6125a5565b905060200201358a8a6001818110610e9957610e996125a5565b905060200201358b8b6000818110610eb357610eb36125a5565b90506020020135610ec491906125d1565b610ece91906125d1565b610ed891906125d1565b610ee291906125d1565b610eec91906125d1565b610ef691906125d1565b610f0091906125d1565b610f0a91906125d1565b610f1491906125d1565b90508061271014610f675760405162461bcd60e51b815260206004820152601e60248201527f53756d206f6620726577617264732073686f756c642062652031303030300000604482015260640161050b565b61138983836000818110610f7d57610f7d6125a5565b90506020020135108015610fab575061138983836001818110610fa257610fa26125a5565b90506020020135105b8015610fd1575061138983836002818110610fc857610fc86125a5565b90506020020135105b8015610ff7575061138983836003818110610fee57610fee6125a5565b90506020020135105b801561101d575061138983836004818110611014576110146125a5565b90506020020135105b801561104357506113898383600581811061103a5761103a6125a5565b90506020020135105b8015611069575061138983836006818110611060576110606125a5565b90506020020135105b801561108f575061138983836007818110611086576110866125a5565b90506020020135105b80156110b55750611389838360088181106110ac576110ac6125a5565b90506020020135105b80156110db5750611389838360098181106110d2576110d26125a5565b90506020020135105b61111d5760405162461bcd60e51b8152602060048201526013602482015272496e76616c69642076616c7565203c3530303160681b604482015260640161050b565b82826000818110611130576111306125a5565b60008052600560209081520291909101357f05b8ccbb9d4d8fb16ea74ce3c29a41f1b461fbdaff4714a0d9a8eb05499746bc555082826001818110611177576111776125a5565b6001600052600560209081520291909101357f1471eb6eb2c5e789fc3de43f8ce62938c7d1836ec861730447e2ada8fd81017b5550828260028181106111bf576111bf6125a5565b6002600052600560209081520291909101357f89832631fb3c3307a103ba2c84ab569c64d6182a18893dcd163f0f1c2090733a555082826003818110611207576112076125a5565b6003600052600560209081520291909101357fa9bc9a3a348c357ba16b37005d7e6b3236198c0e939f4af8c5f19b8deeb8ebc055508282600481811061124f5761124f6125a5565b60046000526005602081815290910292909201357f3eec716f11ba9e820c81ca75eb978ffb45831ef8b7a53e5e422c26008e1ca6d5555083908390818110611299576112996125a5565b6005600081905260209081520291909101357f458b30c2d72bfd2c6317304a4594ecbafe5f729d3111b65fdc3a33bd48e5432d5550828260068181106112e1576112e16125a5565b6006600052600560209081520291909101357f069400f22b28c6c362558d92f66163cec5671cba50b61abd2eecfcd0eaeac518555082826007818110611329576113296125a5565b6007600052600560209081520291909101357feddb6698d7c569ff62ff64f1f1492bf14a54594835ba0faac91f84b4f5d81460555082826008818110611371576113716125a5565b6008600052600560209081520291909101357ffb33122aa9f93cc639ebe80a7bc4784c11e6053dde89c6f4f7e268c6a623da1e5550828260098181106113b9576113b96125a5565b6009600052600560209081520291909101357fc0a4a8be475dfebc377ebef2d7c4ff47656f572a08dd92b81017efcdba0febe155506040517f7772810e3ad8acd693759832bb96eda9b7da2793639ace6af2f1fdc8c0afa810906114209085908590612683565b60405180910390a1505050565b60008111801561143e57506103e881105b61147d5760405162461bcd60e51b815260206004820152601060248201526f496e76616c6964207175616e7469747960801b604482015260640161050b565b600855565b6000805b6008548110156114e9576000600a85856040516114a492919061261f565b908152604080516020928190038301902060008581529252902054905080158015906114d457506114d481611de4565b156114e0578260010192505b50600101611486565b5092915050565b6001546001600160a01b0316331461151a5760405162461bcd60e51b815260040161050b9061262f565b600a8111801561152c57506202a30081105b61156b5760405162461bcd60e51b815260206004820152601060248201526f24b73b30b634b210323ab930ba34b7b760811b604482015260640161050b565b60068190556040518181527f1c44183c85bfea551d74341d87d3e049f755be0969b861e73d0f07d30e560b26906020015b60405180910390a150565b6001600160a01b0381166000908152600d60205260408120549080808084156115f8575060016115d685611de4565b6000868152600c60205260409020600181015460029091015491159550935091505b91939590929450565b6001546001600160a01b0316331461162b5760405162461bcd60e51b815260040161050b9061262f565b6116356000611fd4565b565b6000818152600e6020526040812054801561165c5761165581611de4565b9392505050565b50600092915050565b6000546001146116a45760405162461bcd60e51b815260206004820152600a6024820152695245454e5452414e435960b01b604482015260640161050b565b60026000819055546001600160a01b03166116fa5760405162461bcd60e51b815260206004820152601660248201527514dd185ada5b99d3585b9859d95c881b9bdd081cd95d60521b604482015260640161050b565b6009828260405161170c92919061261f565b9081526040519081900360200190205460ff1661175c5760405162461bcd60e51b815260206004820152600e60248201526d24b73b30b634b2103932b3b4b7b760911b604482015260640161050b565b8261179c5760405162461bcd60e51b815260206004820152601060248201526f125b9d985b1a59081d1bdad95b881a5960821b604482015260640161050b565b6040516331a9108f60e11b81526004810184905233906001600160a01b037f00000000000000000000000000000000000000000000000000000000000000001690636352211e90602401602060405180830381865afa158015611803573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611827919061269f565b6001600160a01b03161461187d5760405162461bcd60e51b815260206004820152601b60248201527f546f6b656e206e6f74206f776e65642066726f6d2073656e6465720000000000604482015260640161050b565b600254604051635d528fc360e11b8152600481018590526000916001600160a01b03169063baa51f86906024016040805180830381865afa1580156118c6573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906118ea91906126bc565b509050806119335760405162461bcd60e51b8152602060048201526016602482015275151bdad95b881cda1bdd5b19081899481cdd185ad95960521b604482015260640161050b565b6000848152600e602052604090205480156119955761195181611de4565b156119955760405162461bcd60e51b8152602060048201526014602482015273086eae4e4cadce8d8f240d2dc40c240dac2e8c6d60631b604482015260640161050b565b336000908152600d602052604090205480156119f8576119b481611de4565b156119f85760405162461bcd60e51b8152602060048201526014602482015273086eae4e4cadce8d8f240d2dc40c240dac2e8c6d60631b604482015260640161050b565b611a028585612026565b905080611a465760405162461bcd60e51b81526020600482015260126024820152714e6f206d6174636820617661696c61626c6560701b604482015260640161050b565b80600e60008881526020019081526020016000208190555080600d6000336001600160a01b03166001600160a01b0316815260200190815260200160002081905550600c6000828152602001908152602001600020600501339080600181540180825580915050600190039060005260206000200160009091909190916101000a8154816001600160a01b0302191690836001600160a01b031602179055506040518060c00160405280600115158152602001600015158152602001600081526020016000815260200142815260200187815250600c60008381526020019081526020016000206006016000336001600160a01b03166001600160a01b0316815260200190815260200160002060008201518160000160006101000a81548160ff02191690831515021790555060208201518160000160016101000a81548160ff02191690831515021790555060408201518160010155606082015181600201556080820151816003015560a082015181600401559050507f2d15cdeceb400aef1ceda76fb5e684ad33b5877ff819da3f41e4b90f9704a50b338288604051611c0d939291906001600160a01b039390931683526020830191909152604082015260600190565b60405180910390a15050600160005550505050565b6001546001600160a01b03163314611c4c5760405162461bcd60e51b815260040161050b9061262f565b600280546001600160a01b0319166001600160a01b0383169081179091556040519081527f55acc64e4a72cc89f8652df08117adc5f4c96f616ea32414ce208b82e370a2db9060200161159c565b6001546001600160a01b03163314611cc45760405162461bcd60e51b815260040161050b9061262f565b6001600160a01b038116611d295760405162461bcd60e51b815260206004820152602660248201527f4f776e61626c653a206e6577206f776e657220697320746865207a65726f206160448201526564647265737360d01b606482015260840161050b565b611d3281611fd4565b50565b6001546001600160a01b03163314611d5f5760405162461bcd60e51b815260040161050b9061262f565b600081118015611d7057506105dd81105b611daf5760405162461bcd60e51b815260206004820152601060248201526f496e76616c6964207175616e7469747960801b604482015260640161050b565b60078190556040518181527f2bebced33ac0c8a2cc832e81eb47ac360bf921544129e8c7726a08f44d18502d9060200161159c565b6000818152600c602052604081206002810154600190910154611e0790426126ea565b1092915050565b60008060018310158015611e23575060058311155b15611e4d5760056000611e376001866126ea565b8152602001908152602001600020549050611fb6565b60068310158015611e5f5750600a8311155b15611e965750600560008190526020527f458b30c2d72bfd2c6317304a4594ecbafe5f729d3111b65fdc3a33bd48e5432d54611fb6565b600b8310158015611ea8575060148311155b15611edf5750600660005260056020527f069400f22b28c6c362558d92f66163cec5671cba50b61abd2eecfcd0eaeac51854611fb6565b60158310158015611ef15750601e8311155b15611f285750600760005260056020527feddb6698d7c569ff62ff64f1f1492bf14a54594835ba0faac91f84b4f5d8146054611fb6565b601f8310158015611f3a575060288311155b15611f715750600860005260056020527ffb33122aa9f93cc639ebe80a7bc4784c11e6053dde89c6f4f7e268c6a623da1e54611fb6565b60298310158015611f83575060328311155b15611fb65750600960005260056020527fc0a4a8be475dfebc377ebef2d7c4ff47656f572a08dd92b81017efcdba0febe1545b80600354611fc49190612664565b61165590655af3107a4000612664565b600180546001600160a01b038381166001600160a01b0319831681179093556040519116919082907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e090600090a35050565b6000808080805b6008548110156120c7576000600a888860405161204b92919061261f565b9081526040805160209281900383019020600085815292529020549050801580159061207b575061207b81611de4565b156120b1576000818152600c60205260409020600381015460059091015410156120a65794506120c7565b8460010194506120be565b826120be57819350600192505b5060010161202d565b508080156120d3575083155b80156120e0575060085483105b156121b257600b8054600101908190556040519094508490600a90612108908990899061261f565b908152604080519182900360209081018320600087815290825282812094909455878452600c815292819020805461ffff1916600190811782554290820181905560068054600284015560078054600385015560048401899055905490548a865295850188905292840152606083019190915260808201929092527f6d8553337c68f22df50c1a8f50319dca0bfbccbddd72e2a9fa87937271eff69b9060a00160405180910390a1505b50505092915050565b60008083601f8401126121cd57600080fd5b50813567ffffffffffffffff8111156121e557600080fd5b6020830191508360208260051b850101111561220057600080fd5b9250929050565b600080600080600080600060a0888a03121561222257600080fd5b873567ffffffffffffffff8082111561223a57600080fd5b6122468b838c016121bb565b909950975060208a013591508082111561225f57600080fd5b5061226c8a828b016121bb565b9096509450506040880135925060608801359150608088013560ff8116811461229457600080fd5b8091505092959891949750929550565b6001600160a01b0381168114611d3257600080fd5b6000602082840312156122cb57600080fd5b8135611655816122a4565b6000602082840312156122e857600080fd5b5035919050565b60008083601f84011261230157600080fd5b50813567ffffffffffffffff81111561231957600080fd5b60208301915083602082850101111561220057600080fd5b8015158114611d3257600080fd5b60008060006040848603121561235457600080fd5b833567ffffffffffffffff81111561236b57600080fd5b612377868287016122ef565b909450925050602084013561238b81612331565b809150509250925092565b600080602083850312156123a957600080fd5b823567ffffffffffffffff8111156123c057600080fd5b6123cc858286016121bb565b90969095509350505050565b600080602083850312156123eb57600080fd5b823567ffffffffffffffff81111561240257600080fd5b6123cc858286016122ef565b60008060006040848603121561242357600080fd5b83359250602084013567ffffffffffffffff81111561244157600080fd5b61244d868287016122ef565b9497909650939450505050565b634e487b7160e01b600052604160045260246000fd5b60006020828403121561248257600080fd5b813567ffffffffffffffff8082111561249a57600080fd5b818401915084601f8301126124ae57600080fd5b8135818111156124c0576124c061245a565b604051601f8201601f19908116603f011681019083821181831017156124e8576124e861245a565b8160405282815287602084870101111561250157600080fd5b826020860160208301376000928101602001929092525095945050505050565b81835260006001600160fb1b0383111561253a57600080fd5b8260051b8083602087013760009401602001938452509192915050565b60808152600061256b60808301888a612521565b828103602084015261257e818789612521565b6001600160a01b039586166040850152939094166060909201919091525095945050505050565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b600082198211156125e4576125e46125bb565b500190565b6001600160a01b038516815260606020820181905260009061260e9083018587612521565b905082604083015295945050505050565b8183823760009101908152919050565b6020808252818101527f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572604082015260600190565b600081600019048311821515161561267e5761267e6125bb565b500290565b602081526000612697602083018486612521565b949350505050565b6000602082840312156126b157600080fd5b8151611655816122a4565b600080604083850312156126cf57600080fd5b82516126da81612331565b6020939093015192949293505050565b6000828210156126fc576126fc6125bb565b50039056fea2646970667358221220daae75095aa090fabeabfa4bfdd981d79ed45a73d93abed0d1a6d03ef35282a764736f6c634300080c0033";

type MatchManagerConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MatchManagerConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MatchManager__factory extends ContractFactory {
  constructor(...args: MatchManagerConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
    this.contractName = "MatchManager";
  }

  deploy(
    _mainSigner: string,
    _bbone: string,
    _flappyAvax: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<MatchManager> {
    return super.deploy(
      _mainSigner,
      _bbone,
      _flappyAvax,
      overrides || {}
    ) as Promise<MatchManager>;
  }
  getDeployTransaction(
    _mainSigner: string,
    _bbone: string,
    _flappyAvax: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _mainSigner,
      _bbone,
      _flappyAvax,
      overrides || {}
    );
  }
  attach(address: string): MatchManager {
    return super.attach(address) as MatchManager;
  }
  connect(signer: Signer): MatchManager__factory {
    return super.connect(signer) as MatchManager__factory;
  }
  static readonly contractName: "MatchManager";
  public readonly contractName: "MatchManager";
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MatchManagerInterface {
    return new utils.Interface(_abi) as MatchManagerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MatchManager {
    return new Contract(address, _abi, signerOrProvider) as MatchManager;
  }
}
