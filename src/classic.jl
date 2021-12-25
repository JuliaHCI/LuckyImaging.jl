
function classic_lucky_image(cube)
    nx, ny, nt = size(cube)
    FT = typeof(one(T) / nt)
    storage = similar(super_cube, FT, (nx, ny))
    classic_lucky_image!(storage, cube)
end

function classic_lucky_image!(storage::AbstractMatrix, cube::AbstractArray; dims=3, metric=:max)
    pdims = sorted_setdiff((1, 2, 3), (dims,))
    if metric === :max
        metric = mapslices(maximum, cube, dims=pdims)
    end
    cutoff = mapslices(a -> quantile(a, q), metric, dims=dims)

    for time_idx in axes(super_cube, 3)
        for flc_idx in axes(super_cube, 4)
            # skip frame if it does not meet selection criterion
            if metric[begin, begin, time_idx, flc_idx] < cutoff[begin, begin, begin, flc_idx]
                continue
            end

            for cam_idx in axes(super_cube, 5)
                frame = @view super_cube[:, :, time_idx, flc_idx, cam_idx]
                # find center of mass and shift frame
                com = center_of_mass(frame; min_value)
                dpos = ImageTransformations.center(frame) .- com
                shifted_frame = shift_frame(frame, reverse(dpos))
                # accumulate mean
                @. output_cube[:, :, flc_idx, cam_idx] += shifted_frame / nt
            end
        end
    end
    return output_cube
end
