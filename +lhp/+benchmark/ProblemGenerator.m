classdef ProblemGenerator
    %% Generate Problems for Benchmarking.
    %
    %   Generates standardized problems from a set of pre-defined gardens (to be
    %   found in the `resources` submodule here) for reusability.

    properties (GetAccess = public, SetAccess = private)
        % Collects metadata such as starting fields that were picked for a
        % specific garden type/size, to make them identical across different
        % tree densities.
        Metadata;
        % Seed used for the RNG
        Seed;
    end


    methods (Access = public)
        function self = ProblemGenerator(kvargs)
            %% Create a ProblemGenerator instance.
            %
            %   Keyword Arguments
            %   -----------------
            %   'Seed': double, default: 12816
            %       A seed for the RNG that is used to e.g. pick appropriate
            %       starting fields in the gardens.
            %   'SameStartForAll': logical, default: true
            %       If set to true, will attempt to find one common starting
            %       field for all gardens that are of the same type and size
            %       (e.g. all regular gardens with 18x18 cells), independent of
            %       tree density. In practice, this will determine a starting
            %       field in the garden with the highest tree density and apply
            %       this to all other gardens of the same type and size, too.
            %       If set to false, a random starting field is picked for every
            %       garden.
            arguments
                kvargs.Seed (1, 1) double = 12816;
                kvargs.SameStartPerGarden (1, 1) logical = true;
            end

            self.Seed = kvargs.Seed;
            % Store current RNG
            rng = RandStream.getGlobalStream();
            rs = RandStream("mt19937ar", "Seed", kvargs.Seed);
            RandStream.setGlobalStream(rs);

            % Prepare Metadata, i.e. generate starting fields for all of the
            % available gardens
            all_gardens = lhp.benchmark.GardenQuery.get_all();

            for ag_idx = 1:numel(all_gardens)
                cur_gq = all_gardens(ag_idx);
                start = cur_gq.get_Garden().get_start([0, 0]);
                all_gardens(ag_idx).Start = start;
            end

            self.Metadata = all_gardens;

            % If requested, make all start fields per garden the same
            if kvargs.SameStartPerGarden
                mdt = all_gardens.metadata_table();
                % Filter by garden type
                gt = unique(mdt.GardenType, 'stable');
                for gt_idx = 1:numel(gt)
                    curtype = (mdt.GardenType == gt(gt_idx));
                    % Filter by garden size
                    gr = unique(mdt.GardenRows(curtype), 'stable');
                    gc = unique(mdt.GardenColumns(curtype), 'stable');
                    for gs_idx = 1:numel(gr)
                        curgs = ((mdt.GardenRows == gr(gs_idx)) & ...
                            (mdt.GardenColumns == gc(gs_idx)));
                        % Filter by tree density
                        td = unique(mdt.TreeDensity(curtype & curgs), 'stable');
                        maxtd = (mdt.TreeDensity == max(td));
                        for td_idx = (numel(td) - 1):-1:1
                            curtd = (mdt.TreeDensity == td(td_idx));
                            % Filter by foliage type
                            ft = unique(mdt.FoliageType(curtype & curgs & curtd), 'stable');
                            for ft_idx = 1:numel(ft)
                                curft = (mdt.FoliageType == ft(ft_idx));
                                firstft = (mdt.FoliageType == ft(1));
                                % Set this gardens starting field to be the same as
                                % the start of the garden with the highest tree
                                % density.
                                self.Metadata(curtype & curgs & curtd & curft).Start = ...
                                    self.Metadata(curtype & curgs & maxtd & firstft).Start;
                            end
                        end
                    end
                end
            end

            % Restore previous RandStream
            RandStream.setGlobalStream(rng);
        end

        function [problem, filterstr] = retrieve(self, kvargs)
            %% Get a specific problem.
            %
            %   Keyword Arguments
            %   -----------------
            %   'GardenType': string
            %       The type of garden to retrieve a problem for. Must match a
            %       prefix of a ``.mat`` file in the ``resources`` submodule.
            %   'GardenSize': double
            %       A 2-element vector of double values that represent the
            %       gardens width and height in cells, respectively.
            %   'TreeDensity': double
            %       The desired tree density in the garden. Must be available in
            %       the gardens found in ``resources``.
            %   'FoliageType': string
            %       Refer to :meth:`+lhp.Garden.random`, keyword argument
            %       'LeavesDistributionType'.
            %
            %   Returns
            %   -------
            %   problem: array of lhp.ProblemData
            %   filterstr: string
            %       The string to filter for the specific garden, given in the
            %       same order as `problem`.
            arguments
                self (1, 1) lhp.benchmark.ProblemGenerator
                kvargs.?lhp.benchmark.GardenQuery
            end

            args = namedargs2cell(kvargs);
            gardens = self.Metadata.get_filtered(args{:});

            problem = lhp.ProblemData.empty(numel(gardens), 0);
            filterstr = string.empty(numel(gardens), 0);
            for g_idx = 1:numel(gardens)
                cur_garden = gardens(g_idx);
                [start_row, start_col] = cur_garden.get_Garden().ind2sub(cur_garden.Start);
                problem(g_idx) = lhp.ProblemData(50, 50, ...
                    "Garten", cur_garden.get_Garden(), ...
                    "Start", [start_row, start_col]);

                filterstr(g_idx) = string(sprintf(strcat('"GardenType",', ...
                    ' "%s", "GardenSize", [%d, %d], "TreeDensity", %.2f,', ...
                    ' "FoliageType", "%s"'), ...
                    cur_garden.GardenType, cur_garden.GardenSize(1), ...
                    cur_garden.GardenSize(2), cur_garden.TreeDensity, ...
                    cur_garden.FoliageType));
            end

            return;
        end
    end

    methods (Static)
        function [problems, pg] = all(kvargs)
            %% Generate problems for all gardens available
            arguments
                kvargs.Seed (1, 1) double = 12816;
            end

            pg = lhp.benchmark.ProblemGenerator("Seed", kvargs.Seed);
        end
    end
end
