// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {TalentBlock} from "../src/TalentBlock.sol";

contract TalentBlockTest is Test {
    TalentBlock talentBlock;

    address owner = makeAddr("owner");
    address seeker = makeAddr("seeker");
    address freelancer = makeAddr("fl");

    string URI = "https://brown-acute-xerinae-416.mypinata.cloud/ipfs/QmTTzRSWnoL14qxshW8zaK3Wkdd9vcMsPf7aCSkzz4ETrD";

    function setUp() public {
        vm.startBroadcast(owner);
        talentBlock = new TalentBlock();
        vm.stopBroadcast();
        vm.deal(seeker, 2 ether);
        vm.deal(owner, 2 ether);
        vm.deal(freelancer, 2 ether);
    }

    function testAddUserURI() public {
        vm.prank(freelancer);
        talentBlock.addUserURI(URI);
        assertEq(talentBlock.getUserURI(freelancer), URI);
    }

    function testAddSeekerURI() public {
        vm.prank(seeker);
        talentBlock.addSeekerURI(URI);
        assertEq(talentBlock.getSeekerURI(seeker), URI);
    }

    function testSeekerCanAddJob() public {
        vm.startPrank(seeker);
        talentBlock.addSeekerURI(URI);
        uint256 twentyPercent = talentBlock.getTwentyPercent(0.1 ether);
        talentBlock.addJob{value: twentyPercent}(URI, 0.1 ether, 30);
        assertEq(1, uint256(talentBlock.getJobStatus(seeker, 1)));
    }

    function testFreeLancerIsSet() public {
        vm.startPrank(seeker);
        talentBlock.addSeekerURI(URI);
        uint256 twentyPercent = talentBlock.getTwentyPercent(1 ether);
        talentBlock.addJob{value: twentyPercent}(URI, 1 ether, 30);
        talentBlock.setFreelancerForJob(1, freelancer);
        assertEq(talentBlock.getJobFreeLancer(seeker, 1), freelancer);
    }

    function testJobCancelled() public {
        vm.startPrank(seeker);
        talentBlock.addSeekerURI(URI);
        uint256 twentyPercent = talentBlock.getTwentyPercent(1 ether);
        talentBlock.addJob{value: twentyPercent}(URI, 1 ether, 30);
        talentBlock.cancelJob(1);
        assertEq(4, uint256(talentBlock.getJobStatus(seeker, 1)));
    }
}
