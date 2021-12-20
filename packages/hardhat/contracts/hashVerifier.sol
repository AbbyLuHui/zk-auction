//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(19642524115522290447760970021746675789341356000653265441069630957431566301675,15809037446102219312954435152879098683824559980020626143453387822004586242317);
        vk.beta2 = Pairing.G2Point([6402738102853475583969787773506197858266321704623454181848954418090577674938,3306678135584565297353192801602995509515651571902196852074598261262327790404], [15158588411628049902562758796812667714664232742372443470614751812018801551665,4983765881427969364617654516554524254158908221590807345159959200407712579883]);
        vk.gamma2 = Pairing.G2Point([11559732032986387107991004021392285783925812861821192530917403151452391805634,10857046999023057135944570762232829481370756359578518086990519993285655852781], [4082367875863433681332203403145435568316851327593401208105741076214120093531,8495653923123431417604973247489272438418190587263600148770280649306958101930]);
        vk.delta2 = Pairing.G2Point([11078114351411396302492606863995638386506537365844689646898417550998267219414,2528491300866434509699704412642731178102268865012248785813458721505586631446], [7646900014588577959937375249841784560277351960820231527167492175864420231155,17448560587075395769884970409122010185777125947946128673908172602768905142360]);
        vk.IC = new Pairing.G1Point[](37);
        vk.IC[0] = Pairing.G1Point(13781710389419072782087202114398729621487355752359777161095262895831156403326,154510782292743106003171734626407771475139015383019743312287477671147911186);
        vk.IC[1] = Pairing.G1Point(21406317406729654608788394889242923439298507456155930444708754905033215822640,10006790094663408063176784997541348475964885737587212408131059153961089172564);
        vk.IC[2] = Pairing.G1Point(12739118346595337713987772135514534096764514012686579324056166898835690899027,14225712997280208704883428148200843523715867627270164000996730715739644219772);
        vk.IC[3] = Pairing.G1Point(21298764720638601941941973829016984319867650107161296490137304865045001819919,14736169711249755634677786311936572033404728878499658254665778920975358850435);
        vk.IC[4] = Pairing.G1Point(16190272652143714764769374529360841233272911625732508499618872454290688097222,6706618142935681196009853288893211602924531021703110753849214919475285347796);
        vk.IC[5] = Pairing.G1Point(18132407682717076351849554296760393217942043458599367640594829647897978299208,9243971007202188163631945505042189403594237126860889375415027832667909058676);
        vk.IC[6] = Pairing.G1Point(7799131275859154332572368965657083371342826553392568804122432916998299009972,9196576543673038553592358385063975920420481096795956922430153928533012981819);
        vk.IC[7] = Pairing.G1Point(637499719951361744819101767858131768541685970050664272779389945922940187239,8553925789879670638364064077746362968395072703498638228543088513777112455837);
        vk.IC[8] = Pairing.G1Point(13467644888372829379359119622920572227176035912454727424232675228175166944442,10389771586775588031539498667834107508358699415194292521932335018151595608606);
        vk.IC[9] = Pairing.G1Point(11537920780327937422607185594058016570741096110941466666202679127730599745776,18517246983909358556287438187012327362240240724297399008833735227055781779299);
        vk.IC[10] = Pairing.G1Point(17738329539636545436222592351246061466209093421181553592000263712494112279692,2999853878376091728786624701266008010024773160174650863229730819437409142090);
        vk.IC[11] = Pairing.G1Point(20686383512918156591952593279650667400773602918768265971476837216629126991816,11379715565278436271970269182690481495399113515929524259322427795069371239507);
        vk.IC[12] = Pairing.G1Point(5860170667824927293633489173707386758140207652390623232582421980654382334031,6691412097960668105726513709186553574477935923288704120301374369512373348865);
        vk.IC[13] = Pairing.G1Point(4445527995788942382350285461470197011337440709765511196166081050256598162363,6689009075968632097776911047670537949103631201017132536267983758835938456976);
        vk.IC[14] = Pairing.G1Point(997277578658865546849738898999894941254698960247936754010194355998391308854,3598183319763823258099994106172882861526690543035641236030578528896749952596);
        vk.IC[15] = Pairing.G1Point(14294512714891341572327442940263292868761277699120191022545021788266407167097,495608438255005132968549025187094120674589620649824896102376232456367381039);
        vk.IC[16] = Pairing.G1Point(6154066214376870259732613802907817597506058284505337711620192270304850141688,1246249800458296109855558228714384575155168015514927886733785986845100232067);
        vk.IC[17] = Pairing.G1Point(11317438307386736751619349912226134214893138418489716441648631447699433935830,5988502592584384948522052795761303451902702566546728101661718731966629299406);
        vk.IC[18] = Pairing.G1Point(9050936757212549305252138424689808315624067071464519757858682739723391466789,6954885365388469260564103687371012355198761718596143402701087497987084785403);
        vk.IC[19] = Pairing.G1Point(4991451607624827405859791537720409093778888033186075049217470391585430166801,2292812928752619457959724759327929336768549205677255164281911527492410338090);
        vk.IC[20] = Pairing.G1Point(16326901062718950085196650232647577844716677945108733384575088185087963316673,11111752772746226299811567163105919744078962308924291163096848770032956171046);
        vk.IC[21] = Pairing.G1Point(4032880571792354376494814145059679426342747792087444312304785752326462194638,1387116318449095293299842363198717244873578665844152459723340690483426442809);
        vk.IC[22] = Pairing.G1Point(2420736161178245979602771601660742744391190367509419485816400463540296035935,209605360798404445192333312238675387683280213409157174428744526897806406137);
        vk.IC[23] = Pairing.G1Point(12404574078714741954156135914317439388464277841110913746608983235331803613677,19328136055779005661972155112979509246812181793144433530608321392334804855339);
        vk.IC[24] = Pairing.G1Point(3348736622325607961675014636025823668762150307241474682084317406265563536039,11481454827128732595102702916149850268522649914136358897887026282337909275616);
        vk.IC[25] = Pairing.G1Point(7840448516456072656091846393133755672026453700917100907221640190065797266662,3056112406170918608449069916680574526741320246776491436732344275784067403817);
        vk.IC[26] = Pairing.G1Point(1931938269566907644867875951237773641595502940197780213185000834334842975353,13882584321718822452418766980067188754881078475366014136418601941888232709808);
        vk.IC[27] = Pairing.G1Point(15693279737471725161597294275055222534914502763745018267203034455278084368738,15198246567419874747375896543962755813751240276572928098276966721563198672701);
        vk.IC[28] = Pairing.G1Point(11112684783148443532442271310503721535968527878825053795505404354715995730678,15866429670740727970395446506125441525502543144272608087192266458248834596690);
        vk.IC[29] = Pairing.G1Point(20910084011820841170596038375478920390269033307050375184284243314763349594155,12293995788524120588628129677647288677680481297098970709621538231089391284333);
        vk.IC[30] = Pairing.G1Point(2499581889251147396166778909200804343798000353395542569000569620868466602467,18894570120124250602075144912977151706299311215351084955814787511612381536419);
        vk.IC[31] = Pairing.G1Point(13736217599255719014565563616522772721561141578887925695464093598042978481179,20384563549930061553823502258200917736962442664219927890627772540792702586095);
        vk.IC[32] = Pairing.G1Point(17357705866630082991588848701467231018189178232599110998853010818477122411691,16563791442677455276169289848614786633642106924774814524783535169782457843028);
        vk.IC[33] = Pairing.G1Point(10782613414865463678239319688365539501634716636640179325933124356892692073977,20153657700645349205214013124312061609995753802503397658667650900421095964252);
        vk.IC[34] = Pairing.G1Point(5929165275407934695278608909144454534557972785576258346985906179476984668324,18934047194911134187270763171713049760674929446312090057007693621201978518599);
        vk.IC[35] = Pairing.G1Point(1988327875732323499280864630391627635495005856305435308933112167350154401003,9236535163205887433330150265177780007996918288278048378479112853129842805314);
        vk.IC[36] = Pairing.G1Point(16459751699316371550426695158459672909375145468698997899157149512996337517039,4885227531448107784178617217655114651382151799753923316252885563512568975130);

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[36] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
