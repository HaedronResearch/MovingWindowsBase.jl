
@testset "rollslices:Int index,no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		rollidx = rollslices(idx, w) |> collect

		@test length(rollidx) == sz-w+1
		@test rollidx == [1:3, 2:4, 3:5, 4:6, 5:7]
	end
end

@testset "rollslices:DateTime index,no gaps" begin
	let st=DateTime(2020), freq=Minute(1), sz=7, idx=st:freq:st+(sz-1)*freq, w=4, wf=(w-1)*freq
		rollidx = rollslices(idx, wf) |> collect

		@test length(rollidx) == sz-w+1
		@test rollidx == [1:4, 2:5, 3:6, 4:7]
	end
end

@testset "roll:Int index (explicit),no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		rollfn = roll(sum, idx=>idx.^2, w; check=TESTCHECK)
		@test length(rollfn) == sz-w+1
		@test rollfn == map(v->sum(v.^2), [1:3, 2:4, 3:5, 4:6, 5:7])
	end
end

@testset "roll:Int index (implicit),no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		rollfn = roll(sum, idx.^2, w; check=TESTCHECK)
		@test length(rollfn) == sz-w+1
		@test rollfn == map(v->sum(v.^2), [1:3, 2:4, 3:5, 4:6, 5:7])
	end
end

@testset "roll:DateTime index,no gaps" begin
	let st=DateTime(2020), freq=Minute(1), sz=7, idx=st:freq:st+(sz-1)*freq, w=4, wf=(w-1)*freq
		v = collect(1:sz)
		rollfn = roll(sum, idx=>v.^2, wf; check=TESTCHECK)

		@test length(rollfn) == sz-w+1
		@test rollfn == map(v->sum(v.^2), [1:4, 2:5, 3:6, 4:7])
	end
end
