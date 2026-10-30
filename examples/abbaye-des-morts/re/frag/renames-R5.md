UpdateWalkLeft -> UpdatePatrolLeft | drives every horizontal patroller, most of which fly (bats, birds, ceiling ghosts, demons); the descriptions already call it a patroller | room survey: kind-2 records are rats, bats, worms, skeletons, knights, ceiling ghosts, birds, demons
UpdateWalkLeft_0 -> UpdatePatrolLeft_0 | follows UpdateWalkLeft | as above
UpdateWalkRight -> UpdatePatrolRight | the same patrol, moving right | kind-3 records: rat (2), bat (8), demon (21); every kind-2 slot after its first turn
UpdateWalkRight_0 -> UpdatePatrolRight_0 | follows UpdateWalkRight | as above
UpdateWalkDown -> UpdatePatrolDown | drives spiders on their threads, fire wheels and flies: nothing walks down | kind-4 records: green spiders (3, 14, 16, 19), fire wheels (22, 23)
UpdateWalkDown_0 -> UpdatePatrolDown_0 | follows UpdateWalkDown | as above
UpdateWalkUp -> UpdatePatrolUp | the same vertical patrol, moving up | kind-5 records: yellow spiders (3), flies (12)
UpdateWalkUp_0 -> UpdatePatrolUp_0 | follows UpdateWalkUp | as above
UpdateCrusaderSignal -> UpdateCrusaderEndScene | path command 5: sets CutsceneDone (ends the first ending scene), then runs as UpdateCrusader; "Signal" does not say what | ending run (poke $850C=$83): CutsceneDone written 00 -> 01 by PC $B1D1 at frame 406, again at 407
