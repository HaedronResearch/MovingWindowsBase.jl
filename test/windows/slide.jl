
@testset "slideslices:Int index,no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		slideidx = slideslices(idx, w) |> collect

		@test length(slideidx) == length(idx)
		@test slideidx == [1:1, 1:2, 1:3, 2:4, 3:5, 4:6, 5:7]
	end
end

@testset "slideslices:DateTime index,no gaps" begin
	let st=DateTime(2020), freq=Minute(1), sz=7, idx=st:freq:st+(sz-1)*freq, w=4, wf=(w-1)*freq
		slideidx = slideslices(idx, wf) |> collect

		@test length(slideidx) == length(idx)
		@test slideidx == [1:1, 1:2, 1:3, 1:4, 2:5, 3:6, 4:7]
	end
end

@testset "slide:Int index (explicit),no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		slidefn = slide(sum, idx=>idx.^2, w)
		@test length(slidefn) == length(idx)
		@test slidefn == map(v->sum(v.^2), [1:1, 1:2, 1:3, 2:4, 3:5, 4:6, 5:7])
	end
end

@testset "slide:Int index (implicit),no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		slidefn = slide(sum, idx.^2, w)
		@test length(slidefn) == length(idx)
		@test slidefn == map(v->sum(v.^2), [1:1, 1:2, 1:3, 2:4, 3:5, 4:6, 5:7])
	end
end

@testset "slide:DateTime index,no gaps" begin
	let st=DateTime(2020), freq=Minute(1), sz=7, idx=st:freq:st+(sz-1)*freq, w=4, wf=(w-1)*freq
		v = collect(1:sz)
		slidefn = slide(sum, idx=>v.^2, wf)

		@test length(slidefn) == length(idx)
		@test slidefn == map(v->sum(v.^2), [1:1, 1:2, 1:3, 1:4, 2:5, 3:6, 4:7])
	end
end
