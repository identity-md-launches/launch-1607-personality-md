// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {PersonalityToken} from "../src/PersonalityToken.sol";

/// @dev All tokens stay within this closed set of actors, allowing exact balance conservation checks.
contract TokenHandler is Test {
    PersonalityToken public immutable token;
    address[4] public actors;

    constructor() {
        token = new PersonalityToken();
        actors[0] = address(this);
        actors[1] = makeAddr("invariant alice");
        actors[2] = makeAddr("invariant bob");
        actors[3] = makeAddr("invariant spender");
    }

    function transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) external {
        address from = actors[fromSeed % actors.length];
        address to = actors[toSeed % actors.length];
        uint256 fromBefore = token.balanceOf(from);
        uint256 toBefore = token.balanceOf(to);
        amount = bound(amount, 0, fromBefore);
        vm.prank(from);
        assertTrue(token.transfer(to, amount));
        assertEq(token.balanceOf(from), from == to ? fromBefore : fromBefore - amount);
        assertEq(token.balanceOf(to), from == to ? toBefore : toBefore + amount);
    }

    function approve(uint256 ownerSeed, uint256 spenderSeed, uint256 amount) external {
        address owner = actors[ownerSeed % actors.length];
        address spender = actors[spenderSeed % actors.length];
        vm.prank(owner);
        assertTrue(token.approve(spender, amount));
        assertEq(token.allowance(owner, spender), amount);
    }

    function transferFrom(uint256 ownerSeed, uint256 spenderSeed, uint256 toSeed, uint256 amount) external {
        address owner = actors[ownerSeed % actors.length];
        address spender = actors[spenderSeed % actors.length];
        address to = actors[toSeed % actors.length];
        uint256 approved = token.allowance(owner, spender);
        uint256 ownerBefore = token.balanceOf(owner);
        uint256 toBefore = token.balanceOf(to);
        amount = bound(amount, 0, approved < ownerBefore ? approved : ownerBefore);
        vm.prank(spender);
        assertTrue(token.transferFrom(owner, to, amount));
        assertEq(token.allowance(owner, spender), approved == type(uint256).max ? approved : approved - amount);
        assertEq(token.balanceOf(owner), owner == to ? ownerBefore : ownerBefore - amount);
        assertEq(token.balanceOf(to), owner == to ? toBefore : toBefore + amount);
    }
}

contract PersonalityTokenInvariantTest is Test {
    uint256 private constant SUPPLY = 1_000_000_000_000_000_000_000_000_000;
    TokenHandler private handler;
    PersonalityToken private token;

    function setUp() public {
        handler = new TokenHandler();
        token = handler.token();
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = TokenHandler.transfer.selector;
        selectors[1] = TokenHandler.approve.selector;
        selectors[2] = TokenHandler.transferFrom.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function invariant_totalSupplyNeverChanges() public view {
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(address(0)), 0);
    }

    function invariant_balancesConserveEntireSupply() public view {
        uint256 sum;
        for (uint256 i; i < 4; ++i) {
            sum += token.balanceOf(handler.actors(i));
        }
        assertEq(sum, SUPPLY);
    }
}
