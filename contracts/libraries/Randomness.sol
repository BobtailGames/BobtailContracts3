// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

library Randomness {
    function generate(uint256 _block, uint256 _size)
        internal
        view
        returns (uint256[] memory randomnessExpanded)
    {
        uint256 randomness = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(_block - 1),
                    blockhash(_block - 3),
                    blockhash(_block - 5),
                    blockhash(_block - 8),
                    blockhash(_block - 15),
                    _block,
                    blockhash(_block - 10),
                    blockhash(_block - 9),
                    blockhash(_block - 12)
                )
            )
        );
        randomnessExpanded = randomnessExpand(randomness, _size);
    }

    function randomnessExpand(uint256 _randomValue, uint256 _n)
        internal
        pure
        returns (uint256[] memory _expandedValues)
    {
        _expandedValues = new uint256[](_n);
        for (uint256 i = 0; i < _n; i++) {
            _expandedValues[i] = uint256(
                keccak256(abi.encode(_randomValue, i))
            );
        }
    }
}
