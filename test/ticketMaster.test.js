//Assignment - Eduardo Pezzi

const TicketMaster = artifacts.require("TicketMaster");
const truffleAssert = require("truffle-assertions");

contract("TicketMaster", accounts => {
  describe("ticketMaster contract", () => {
    it("1-should deploy TicketMaster Contract", async () => {
      const ticketMaster = await TicketMaster.deployed();
      assert.ok(ticketMaster.address, "Contract not deployed");
    });

    it("2-should account[1] buy a ticket and check the OWNEROF ticket", async () => {
      const price = 10000;
      const buyer = await accounts[1];
      const tokenID_1 = 1;
      const ticketMaster = await TicketMaster.deployed();
      ticketMaster.BuyTicket.sendTransaction(tokenID_1, {
        from: buyer,
        value: price
      });
      ownerOf3 = await ticketMaster.ownerOf.call(tokenID_1);
      assert.equal(
        ownerOf3.toString(),
        buyer.toString(),
        "Transaction not completed, Account[1] do NOT own ticket 1"
      );
    });

    it("3-should get the BALANCEOF account", async () => {
      const price = 10000;
      const buyer = await accounts[2];
      const tokenID_1 = 11;
      const tokenID_2 = 12;
      const ticketMaster = await TicketMaster.deployed();
      ticketMaster.BuyTicket.sendTransaction(tokenID_1, {
        from: buyer,
        value: price
      });
      ticketMaster.BuyTicket.sendTransaction(tokenID_2, {
        from: buyer,
        value: price
      });
      balanceOfAcc2 = await ticketMaster.balanceOf.call(buyer);
      assert.equal(
        balanceOfAcc2,
        2,
        "Transaction not completed, Account[1] do NOT own ticket 1"
      );
    });

    //==== cap_max os set in the file "2_deploy_contracts in Migrate file" ===//
    it("4-should get the total Supply", async () => {
      const ticketMaster = await TicketMaster.deployed();
      capmax = await ticketMaster.cap_max.call();
      assert.equal(capmax.toString(), 100, "cap_max is not matching");
    });
    it("5-should test approve() and safeTransferFrom() function", async () => {
      const price = 10000;
      const tokenID = 12;
      const _to = await accounts[1];
      const _from = await accounts[2];
      const _spender = await accounts[3];
      const ticketMaster = await TicketMaster.deployed();

      await ticketMaster.approve.sendTransaction(_spender, tokenID, {
        from: _from
      });

      await ticketMaster.safeTransferFrom.sendTransaction(_from, _to, tokenID, {
        from: _spender
      });
      const _toBalance = await ticketMaster.balanceOf.call(_to);
      assert.equal(
        _toBalance.toNumber(),
        "2",
        "Destinatary haven't received the ticket"
      );
    });
    it("6-should test TransferFrom() function", async () => {
      const price = 10000;
      const tokenID = 21;
      const _to = await accounts[4];
      const _from = await accounts[5];
      const ticketMaster = await TicketMaster.deployed();
      await ticketMaster.BuyTicket.sendTransaction(tokenID, {
        from: _from,
        value: price
      });
      await ticketMaster.transferFrom.sendTransaction(_from, _to, tokenID, {
        from: _from
      });
      const ownerOfToken7 = await ticketMaster.ownerOf.call(tokenID);
      assert.equal(
        ownerOfToken7.toString(),
        _to.toString(),
        "Destinatary haven't received the ticket"
      );
    });
    it("7-should  getApproved() function return Operator Address", async () => {
      const price = 10000;
      const tokenID = 21;
      const _from = await accounts[4];
      const _spender = await accounts[6];
      const ticketMaster = await TicketMaster.deployed();
      await ticketMaster.approve.sendTransaction(_spender, tokenID, {
        from: _from
      });
      const _spenderApproved = await ticketMaster.getApproved.call(tokenID);

      assert.equal(
        _spenderApproved.toString(),
        _spender.toString(),
        "getApproved() does NOT returned Spender approval"
      );
    });
    it("8-should setApproveForAll() approve and disapprove while  isApprovedForAll() function check Operator", async () => {
      const price = 10000;
      const tokenID_1 = 21;
      const tokenID_2 = 22;
      const _to = await accounts[5];
      const _from = await accounts[4];
      const _spender = await accounts[6];
      const ticketMaster = await TicketMaster.deployed();
      await ticketMaster.BuyTicket.sendTransaction(tokenID_2, {
        from: _from,
        value: price
      });
      await ticketMaster.setApprovalForAll.sendTransaction(_spender, true, {
        from: _from
      });
      let _spenderApproved = await ticketMaster.isApprovedForAll.call(
        _from,
        _spender
      );
      assert.equal(
        _spenderApproved.toString(),
        "true",
        "Operator/Spender is NOT approved"
      );
      await ticketMaster.setApprovalForAll.sendTransaction(_spender, false, {
        from: _from
      });
      let _spenderDisapproved = await ticketMaster.isApprovedForAll.call(
        _from,
        _spender
      );
      assert.equal(
        _spenderDisapproved.toString(),
        "false",
        "setApproveForAll() function does NOT disapproved"
      );
    });
    it("9-ERC165 supportsInterface() test", async () => {
      const erc721_selector = "0x80ac58cd";
      const ticketMaster = await TicketMaster.deployed();
      validate = await ticketMaster.supportsInterface.call(erc721_selector);
      assert.equal(validate.toString(), "true", "ERC721 is NOT validated");
    });
    it("10-should emit Transfer event", async () => {
      const tokenID = 29;
      const _to = await accounts[5];
      const _price = 100000;
      const ticketMaster = await TicketMaster.deployed();
      _buyTx = await ticketMaster.BuyTicket.sendTransaction(tokenID, {
        from: _to,
        value: _price
      });
      truffleAssert.eventEmitted(_buyTx, "Transfer", async ev => {
        assert(
          ev["_from"] == 0x000000000000000000000000000000000000000 &&
            ev["_to"] == _to &&
            ev["_tokenId"] == tokenID,
          "Transfer has NOT emitted"
        );
      });
    });
    it("11-should emit Approval event", async () => {
      const tokenID = 99;
      const _from = await accounts[5];
      const _spender = await accounts[7];
      const ticketMaster = await TicketMaster.deployed();
      _buyTx = await ticketMaster.BuyTicket.sendTransaction(tokenID, {
        from: _from,
        value: 100000
      });
      _approvalTx = await ticketMaster.approve.sendTransaction(
        _spender,
        tokenID,
        {
          from: _from
        }
      );
      truffleAssert.eventEmitted(_approvalTx, "Approval", async ev => {
        assert(
          ev["_owner"] == _from &&
            ev["_approved"] == _spender &&
            ev["_tokenId"] == tokenID,
          "Approval has NOT emitted"
        );
      });
    });
    it("12-should emit ApprovalForAll event", async () => {
      const _from = await accounts[0];
      const _spender = await accounts[2];
      const ticketMaster = await TicketMaster.deployed();
      _approvalTx = await ticketMaster.setApprovalForAll.sendTransaction(
        _spender,
        true,
        {
          from: _from
        }
      );
      truffleAssert.eventEmitted(_approvalTx, "ApprovalForAll", async ev => {
        assert(
          ev["_owner"].toString() == _from &&
            ev["_operator"].toString() == _spender &&
            ev["_approved"].toString() == "true",
          "ApprovalForAll has NOT emitted"
        );
      });
    });
  });
});
