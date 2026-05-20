
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
		slidefn = slide(sum, idx=>idx.^2, w; check=TESTCHECK)
		@test length(slidefn) == length(idx)
		@test slidefn == map(v->sum(v.^2), [1:1, 1:2, 1:3, 2:4, 3:5, 4:6, 5:7])
	end
end

@testset "slide:Int index (implicit),no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		slidefn = slide(sum, idx.^2, w; check=TESTCHECK)
		@test length(slidefn) == length(idx)
		@test slidefn == map(v->sum(v.^2), [1:1, 1:2, 1:3, 2:4, 3:5, 4:6, 5:7])
	end
end

@testset "slide:DateTime index,no gaps" begin
	let st=DateTime(2020), freq=Minute(1), sz=7, idx=st:freq:st+(sz-1)*freq, w=4, wf=(w-1)*freq
		v = collect(1:sz)
		slidefn = slide(sum, idx=>v.^2, wf; check=TESTCHECK)

		@test length(slidefn) == length(idx)
		@test slidefn == map(v->sum(v.^2), [1:1, 1:2, 1:3, 1:4, 2:5, 3:6, 4:7])
	end
end

@testset "slidesum:Int index (implicit),no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		inp = idx.^2
		slidefn = slidesum(inp, w; check=TESTCHECK)
		output = map(v->sum(v.^2), [1:1, 1:2, 1:3, 2:4, 3:5, 4:6, 5:7])
		@test slidefn == output
	end
end

@testset "slidemean:Int index (implicit),no gaps" begin
	let sz=7, idx=collect(1:sz), w=3
		inp = map(float, idx.^2)
		slidefn = slidemean(inp, w; check=TESTCHECK)
		output = map(v->sum(float, v.^2), [1:1, 1:2, 1:3, 2:4, 3:5, 4:6, 5:7])
		for i=eachindex(output)
			output[i] = ifelse(i<w, output[i]/i, output[i]/w)
		end
		@test slidefn == output
	end
end

@testset "slidedot:Int index (implicit),no gaps" begin
	let sz=7,x=collect(1:sz)
		let w=(1,-2) 
			wx1 = x[1:end-1] * w[1] 
			wx2 = x[2:end-0] * w[2]
			wx = vcat(x[1], wx1 + wx2)
			@test slidedot(x, w) == wx
		end
		let w=(-3,1,0)
			wx1 = x[1:end-2] * w[1] 
			wx2 = x[2:end-1] * w[2] 
			wx3 = x[3:end-0] * w[3]
			wx = vcat(x[1:2], wx1 + wx2 + wx3)
			@test slidedot(x, w) == wx
		end
	end
end

@testset "slidedotsym:Int index (implicit),no gaps" begin
	let x=collect(1.:10.)
		let w=(1.,2.,1.) 
			out = slidedotsym(x, w)
			@test out[01] ≈ (1*2 + 2*1)/sum(w[2:3])   # left edge
			@test out[02] ≈ (1*1 + 2*2 + 3*1)/sum(w)  # left
			@test out[05] ≈ (4*1 + 5*2 + 6*1)/sum(w)  # middle
			@test out[09] ≈ (8*1 + 9*2 + 10*1)/sum(w) # right
			@test out[10] ≈ (9*1 + 10*2)/sum(w[1:2])  # right edge
		end
		let w=(1.,4.,6.,4.,1.)
			out = slidedotsym(x, w)
			@test out[01] ≈ (1*6 + 2*4 + 3*1)/sum(w[3:5])        # left edge
			@test out[02] ≈ (1*4 + 2*6 + 3*4 + 4*1)/sum(w[2:5])  # left edge
			@test out[05] ≈ (3*1 + 4*4 + 5*6 + 6*4 + 7*1)/sum(w) # middle
			@test out[09] ≈ (7*1 + 8*4 + 9*6 + 10*4)/sum(w[1:4]) # right edge
			@test out[10] ≈ (8*1 + 9*4 + 10*6)/sum(w[1:3])       # right edge
		end
	end
end

@testset "slidedsp:Int index (implicit),no gaps" begin
	let sz=4,x=collect(1:sz)
		let w=(1,2),wo=(1,0)
			out=[1,0,0,0]
			out[2] = w[1]*x[1] + w[2]*x[2] + wo[1] * out[1] + wo[2] * out[2]
			out[3] = w[1]*x[2] + w[2]*x[3] + wo[1] * out[2] + wo[2] * out[3]
			out[4] = w[1]*x[3] + w[2]*x[4] + wo[1] * out[3] + wo[2] * out[4]
			@test slidedsp(x, w, wo) == out
		end
		let w=(-1,0,3),wo=(1,-1,0)
			out=[1,2,0,0]
			out[3] = w[1]*x[1] + w[2]*x[2] + w[3]*x[3] +
					wo[1]*out[1] + wo[2]*out[2] + wo[3]*out[3]
			out[4] = w[1]*x[2] + w[2]*x[3] + w[3]*x[4] +
					wo[1]*out[2] + wo[2]*out[3] + wo[3]*out[4]
			@test slidedsp(x, w, wo) == out
		end
		let w=(-1,0,3),wo=(1,-1,0)
			out = zeros(Int, sz)
			out[3] = w[1]*x[1] + w[2]*x[2] + w[3]*x[3] +
					wo[1]*out[1] + wo[2]*out[2] + wo[3]*out[3]
			out[4] = w[1]*x[2] + w[2]*x[3] + w[3]*x[4] +
					wo[1]*out[2] + wo[2]*out[3] + wo[3]*out[4]
			out[1] = 0
			out[2] = 0
			inp = zeros(Int, sz)
			@test slidedsp!(inp, x, w, wo) == out
		end
		@test_throws DimensionMismatch slidedsp(x, (1,3,4), (1,0))
	end
end
