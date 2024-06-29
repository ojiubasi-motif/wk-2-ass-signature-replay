## Guild Airdrop Manager
```GuildAirdrop```  contract manages the two airdrop tokens ```AirdropT1``` and ```AirdropT2```. 
A user is qualified for the airdrops, if she has at least ```1e9``` of the network's native token in her wallet.
However she must ```checkEligibility``` if not she wouldn't be able to claim any airdrop.
After checking, she can **either** choose to claim  **any/both** airdrops directly to her wallet or ```claim``` them to another wallet of her choice. If she chose the latter, then she must ```Sign``` in the process. 
the way the [```GuildAirdrop``` contract](https://github.com/ojiubasi-motif/wk-2-ass-signature-replay/blob/master/src/AirdropSignature.sol) carry out the signature exposes the user to a ```signature replay``` attack as both tokens will be claimed even if she only signed for one token. Test is seen in the [```AirdropTest.t.sol```](https://github.com/ojiubasi-motif/wk-2-ass-signature-replay/blob/master/test/AirdropTest.t.sol)