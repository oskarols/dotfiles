function curry(func, num_args)
  num_args = num_args or debug.getinfo(func, "u").nparams

  if num_args < 2 then return func end

  local function helper(argtrace, n)
    if n < 1 then
      return func(unpack(flatten(argtrace)))
    else
      return function (...)
        return helper({argtrace, ...}, n - select("#", ...))
      end
    end
  end
  return helper({}, num_args)
end

