function bee_wrapper = wrapper(swargs, kvargs)
    %% Convenienve function to create bee algorithm wrappers.
    %
    %   This function serves as a convenience function to creating wrappers for
    %   the bee algorithm. It simplifies the function call from::
    %
    %       lhp.algo.StochasticWrapper(...
    %           @lhp.algo.stochastic.bee.bienenalgorithmus, ...
    %           "Bienen", ...
    %           lhp.algo.stochastic.bee.BeeParameters(), ...
    %           [ Other Arguments ]);
    %
    %   to simply::
    %
    %       lhp.algo.stochastic.bee.wrapper()
    %
    %   Which is sufficient for most cases where the default parameters aren't
    %   changed. If any of the parameters shall be changed, the user can access
    %   the regular Key-Value parameters that e.g. `StochasticWrapper` offers
    %   already.
    %   To override wrapper-specific parameters, see below.
    %
    %   Keyword Arguments
    %   -----------------
    %   'AlgorithmName': string, default: "Bienen"
    %       Custom name to give to the algorithm. This is mostly cosmetic and
    %       useful to differ e.g. between multiple instances of the same
    %       algorithm with slightly different parameters
    %   'AlgorithmParams': BeeParameters, default: ``BeeParameters()``
    %       Custom parameters to give to the algorithm.
    %   'PLACEHOLDER':
    %       Any other keyword arguments that can be passed to
    %       `lhp.algo.StochasticWrapper`.
    arguments
        swargs.?lhp.algo.StochasticWrapper
        kvargs.AlgorithmName (1, 1) string = "Bienen";
        kvargs.AlgorithmParams (1, 1) lhp.algo.stochastic.bee.BeeParameters = ...
            lhp.algo.stochastic.bee.BeeParameters();
    end

    % Convert additional args to cell array for expansion later on
    swargs_cell = namedargs2cell(swargs);
    % Create the class instance
    bee_wrapper = lhp.algo.StochasticWrapper(...
        @lhp.algo.stochastic.bee.bienenalgorithmus, ...
        kvargs.AlgorithmName, kvargs.AlgorithmParams, ...
        swargs_cell{:});

    return;
end
