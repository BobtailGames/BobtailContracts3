/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import { FunctionFragment, Result, EventFragment } from "@ethersproject/abi";
import { Listener, Provider } from "@ethersproject/providers";
import { TypedEventFilter, TypedEvent, TypedListener, OnEvent } from "./common";

export declare namespace IBobtailNFT {
  export type NftEntityStruct = {
    lvl: BigNumberish;
    exp: BigNumberish;
    timestampMint: BigNumberish;
    block: BigNumberish;
    revealed: BigNumberish;
    staked: BigNumberish;
    skin: BigNumberish;
    face: BigNumberish;
    rarity: BigNumberish;
    pendingReward: BigNumberish;
  };

  export type NftEntityStructOutput = [
    number,
    number,
    BigNumber,
    BigNumber,
    number,
    number,
    number,
    number,
    number,
    BigNumber
  ] & {
    lvl: number;
    exp: number;
    timestampMint: BigNumber;
    block: BigNumber;
    revealed: number;
    staked: number;
    skin: number;
    face: number;
    rarity: number;
    pendingReward: BigNumber;
  };
}

export interface StakingManagerInterface extends utils.Interface {
  contractName: "StakingManager";
  functions: {
    "bbone()": FunctionFragment;
    "flappyAvax()": FunctionFragment;
    "isAddressStaking(address)": FunctionFragment;
    "isStaked(uint256)": FunctionFragment;
    "matchManager()": FunctionFragment;
    "maxStakingTokensPerAccount()": FunctionFragment;
    "owner()": FunctionFragment;
    "renounceOwnership()": FunctionFragment;
    "rewardPerMinute()": FunctionFragment;
    "setMatchManager(address)": FunctionFragment;
    "setMaxStakingTokensPerAccount(uint256)": FunctionFragment;
    "setRewardPerMinute(uint256)": FunctionFragment;
    "stake(uint256[])": FunctionFragment;
    "stakedItems(uint256)": FunctionFragment;
    "stakedTokensOf(address)": FunctionFragment;
    "stakedTokensWithInfoOf(address)": FunctionFragment;
    "stakingCountForAddress(address)": FunctionFragment;
    "stakingReward(uint256)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
    "withdrawOrClaim(uint256[],bool)": FunctionFragment;
  };

  encodeFunctionData(functionFragment: "bbone", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "flappyAvax",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "isAddressStaking",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "isStaked",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "matchManager",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "maxStakingTokensPerAccount",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "renounceOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "rewardPerMinute",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "setMatchManager",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "setMaxStakingTokensPerAccount",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "setRewardPerMinute",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "stake",
    values: [BigNumberish[]]
  ): string;
  encodeFunctionData(
    functionFragment: "stakedItems",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "stakedTokensOf",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "stakedTokensWithInfoOf",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "stakingCountForAddress",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "stakingReward",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawOrClaim",
    values: [BigNumberish[], boolean]
  ): string;

  decodeFunctionResult(functionFragment: "bbone", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "flappyAvax", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "isAddressStaking",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "isStaked", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "matchManager",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "maxStakingTokensPerAccount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "renounceOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "rewardPerMinute",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setMatchManager",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setMaxStakingTokensPerAccount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setRewardPerMinute",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "stake", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "stakedItems",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "stakedTokensOf",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "stakedTokensWithInfoOf",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "stakingCountForAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "stakingReward",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawOrClaim",
    data: BytesLike
  ): Result;

  events: {
    "MatchManagerUpdated(address)": EventFragment;
    "MaxStakingTokensPerAccountUpdated(uint256)": EventFragment;
    "OwnershipTransferred(address,address)": EventFragment;
    "RewardPerMinuteUpdated(uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "MatchManagerUpdated"): EventFragment;
  getEvent(
    nameOrSignatureOrTopic: "MaxStakingTokensPerAccountUpdated"
  ): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RewardPerMinuteUpdated"): EventFragment;
}

export type MatchManagerUpdatedEvent = TypedEvent<
  [string],
  { matchDuration: string }
>;

export type MatchManagerUpdatedEventFilter =
  TypedEventFilter<MatchManagerUpdatedEvent>;

export type MaxStakingTokensPerAccountUpdatedEvent = TypedEvent<
  [BigNumber],
  { maxStakingTokensPerAccount: BigNumber }
>;

export type MaxStakingTokensPerAccountUpdatedEventFilter =
  TypedEventFilter<MaxStakingTokensPerAccountUpdatedEvent>;

export type OwnershipTransferredEvent = TypedEvent<
  [string, string],
  { previousOwner: string; newOwner: string }
>;

export type OwnershipTransferredEventFilter =
  TypedEventFilter<OwnershipTransferredEvent>;

export type RewardPerMinuteUpdatedEvent = TypedEvent<
  [BigNumber],
  { rewardPerMinute: BigNumber }
>;

export type RewardPerMinuteUpdatedEventFilter =
  TypedEventFilter<RewardPerMinuteUpdatedEvent>;

export interface StakingManager extends BaseContract {
  contractName: "StakingManager";
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: StakingManagerInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    bbone(overrides?: CallOverrides): Promise<[string]>;

    flappyAvax(overrides?: CallOverrides): Promise<[string]>;

    isAddressStaking(
      _address: string,
      overrides?: CallOverrides
    ): Promise<[boolean] & { staked: boolean }>;

    isStaked(
      _tokenId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [boolean, BigNumber] & { staked: boolean; timestampStake: BigNumber }
    >;

    matchManager(overrides?: CallOverrides): Promise<[string]>;

    maxStakingTokensPerAccount(overrides?: CallOverrides): Promise<[BigNumber]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    renounceOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    rewardPerMinute(overrides?: CallOverrides): Promise<[BigNumber]>;

    setMatchManager(
      _matchManager: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    setMaxStakingTokensPerAccount(
      _maxStakingTokensPerAccount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    setRewardPerMinute(
      _rewardPerMinute: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    stake(
      _tokenIds: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    stakedItems(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [boolean, BigNumber] & { staked: boolean; timestampStake: BigNumber }
    >;

    stakedTokensOf(
      _account: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber[]] & { tokenIds: BigNumber[] }>;

    stakedTokensWithInfoOf(
      _account: string,
      overrides?: CallOverrides
    ): Promise<[IBobtailNFT.NftEntityStructOutput[]]>;

    stakingCountForAddress(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    stakingReward(
      _tokenId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    withdrawOrClaim(
      _tokenIds: BigNumberish[],
      _unstake: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  bbone(overrides?: CallOverrides): Promise<string>;

  flappyAvax(overrides?: CallOverrides): Promise<string>;

  isAddressStaking(
    _address: string,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isStaked(
    _tokenId: BigNumberish,
    overrides?: CallOverrides
  ): Promise<
    [boolean, BigNumber] & { staked: boolean; timestampStake: BigNumber }
  >;

  matchManager(overrides?: CallOverrides): Promise<string>;

  maxStakingTokensPerAccount(overrides?: CallOverrides): Promise<BigNumber>;

  owner(overrides?: CallOverrides): Promise<string>;

  renounceOwnership(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  rewardPerMinute(overrides?: CallOverrides): Promise<BigNumber>;

  setMatchManager(
    _matchManager: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  setMaxStakingTokensPerAccount(
    _maxStakingTokensPerAccount: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  setRewardPerMinute(
    _rewardPerMinute: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  stake(
    _tokenIds: BigNumberish[],
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  stakedItems(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<
    [boolean, BigNumber] & { staked: boolean; timestampStake: BigNumber }
  >;

  stakedTokensOf(
    _account: string,
    overrides?: CallOverrides
  ): Promise<BigNumber[]>;

  stakedTokensWithInfoOf(
    _account: string,
    overrides?: CallOverrides
  ): Promise<IBobtailNFT.NftEntityStructOutput[]>;

  stakingCountForAddress(
    arg0: string,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  stakingReward(
    _tokenId: BigNumberish,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  transferOwnership(
    newOwner: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  withdrawOrClaim(
    _tokenIds: BigNumberish[],
    _unstake: boolean,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    bbone(overrides?: CallOverrides): Promise<string>;

    flappyAvax(overrides?: CallOverrides): Promise<string>;

    isAddressStaking(
      _address: string,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isStaked(
      _tokenId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [boolean, BigNumber] & { staked: boolean; timestampStake: BigNumber }
    >;

    matchManager(overrides?: CallOverrides): Promise<string>;

    maxStakingTokensPerAccount(overrides?: CallOverrides): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<string>;

    renounceOwnership(overrides?: CallOverrides): Promise<void>;

    rewardPerMinute(overrides?: CallOverrides): Promise<BigNumber>;

    setMatchManager(
      _matchManager: string,
      overrides?: CallOverrides
    ): Promise<void>;

    setMaxStakingTokensPerAccount(
      _maxStakingTokensPerAccount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    setRewardPerMinute(
      _rewardPerMinute: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    stake(_tokenIds: BigNumberish[], overrides?: CallOverrides): Promise<void>;

    stakedItems(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<
      [boolean, BigNumber] & { staked: boolean; timestampStake: BigNumber }
    >;

    stakedTokensOf(
      _account: string,
      overrides?: CallOverrides
    ): Promise<BigNumber[]>;

    stakedTokensWithInfoOf(
      _account: string,
      overrides?: CallOverrides
    ): Promise<IBobtailNFT.NftEntityStructOutput[]>;

    stakingCountForAddress(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    stakingReward(
      _tokenId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: string,
      overrides?: CallOverrides
    ): Promise<void>;

    withdrawOrClaim(
      _tokenIds: BigNumberish[],
      _unstake: boolean,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "MatchManagerUpdated(address)"(
      matchDuration?: null
    ): MatchManagerUpdatedEventFilter;
    MatchManagerUpdated(matchDuration?: null): MatchManagerUpdatedEventFilter;

    "MaxStakingTokensPerAccountUpdated(uint256)"(
      maxStakingTokensPerAccount?: null
    ): MaxStakingTokensPerAccountUpdatedEventFilter;
    MaxStakingTokensPerAccountUpdated(
      maxStakingTokensPerAccount?: null
    ): MaxStakingTokensPerAccountUpdatedEventFilter;

    "OwnershipTransferred(address,address)"(
      previousOwner?: string | null,
      newOwner?: string | null
    ): OwnershipTransferredEventFilter;
    OwnershipTransferred(
      previousOwner?: string | null,
      newOwner?: string | null
    ): OwnershipTransferredEventFilter;

    "RewardPerMinuteUpdated(uint256)"(
      rewardPerMinute?: null
    ): RewardPerMinuteUpdatedEventFilter;
    RewardPerMinuteUpdated(
      rewardPerMinute?: null
    ): RewardPerMinuteUpdatedEventFilter;
  };

  estimateGas: {
    bbone(overrides?: CallOverrides): Promise<BigNumber>;

    flappyAvax(overrides?: CallOverrides): Promise<BigNumber>;

    isAddressStaking(
      _address: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isStaked(
      _tokenId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    matchManager(overrides?: CallOverrides): Promise<BigNumber>;

    maxStakingTokensPerAccount(overrides?: CallOverrides): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    renounceOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    rewardPerMinute(overrides?: CallOverrides): Promise<BigNumber>;

    setMatchManager(
      _matchManager: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    setMaxStakingTokensPerAccount(
      _maxStakingTokensPerAccount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    setRewardPerMinute(
      _rewardPerMinute: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    stake(
      _tokenIds: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    stakedItems(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    stakedTokensOf(
      _account: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    stakedTokensWithInfoOf(
      _account: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    stakingCountForAddress(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    stakingReward(
      _tokenId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    withdrawOrClaim(
      _tokenIds: BigNumberish[],
      _unstake: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    bbone(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    flappyAvax(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    isAddressStaking(
      _address: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isStaked(
      _tokenId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    matchManager(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    maxStakingTokensPerAccount(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    renounceOwnership(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    rewardPerMinute(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    setMatchManager(
      _matchManager: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    setMaxStakingTokensPerAccount(
      _maxStakingTokensPerAccount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    setRewardPerMinute(
      _rewardPerMinute: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    stake(
      _tokenIds: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    stakedItems(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    stakedTokensOf(
      _account: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    stakedTokensWithInfoOf(
      _account: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    stakingCountForAddress(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    stakingReward(
      _tokenId: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    withdrawOrClaim(
      _tokenIds: BigNumberish[],
      _unstake: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}