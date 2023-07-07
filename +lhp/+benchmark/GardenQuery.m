classdef GardenQuery
    %% Query available gardens.
    %
    %   Retrieve the raw garden matrices of the gardens stored in ``resources``,
    %   or directly query information about available gardens, such as sizes,
    %   tree densities, etc.

    properties (GetAccess = public, SetAccess = public)
        % Type of a garden
        GardenType (1, 1) string;
        % Size of a garden
        GardenSize (1, 2) double {mustBeNonnegative, mustBeInteger};
        % Tree density in a garden
        TreeDensity (1, 1) double {mustBeInRange(TreeDensity, 0, 1)};
        % Foliage Type in a garden
        FoliageType (1, 1) string {mustBeMember(FoliageType, ...
            ["GaussAroundTrees", "Uniform1-5", "Uniform1-10"])} ...
            = "GaussAroundTrees";
    end

    properties (Access = private)
        % Actual garden matrix
        GardenObject;
    end

    properties (Access = ?lhp.benchmark.ProblemGenerator)
        Start;
    end
    
    properties (Constant, Access = private)
        FOLIAGE_TYPES = ["GaussAroundTrees", "Uniform1-5", "Uniform1-10"];
    end

    methods
        function self = GardenQuery(garden, type, size, density, foliage)
            if nargin == 0
                return;
            end

            self.GardenObject = garden;
            self.GardenType = type;
            self.GardenSize = size;
            self.TreeDensity = density;
            self.FoliageType = foliage;
        end

        function garden = get_Garden(self)
            garden = self.GardenObject;
        end
        
        function tb = metadata_table(self)
            %% Get a table with all gardens metadata.
            %
            %   Metadata includes:
            %
            %   - Garden sizes
            %   - Garden types
            %   - Tree density
            tb = table('Size', [numel(self), 5], ...
                'VariableTypes', {'string', 'double', 'double', 'double', 'string'}, ...
                'VariableNames', {'GardenType', 'GardenRows', ...
                    'GardenColumns', 'TreeDensity', 'FoliageType'});
            for gq_idx = 1:numel(self)
                tb.GardenType(gq_idx) = self(gq_idx).GardenType;
                tb.GardenRows(gq_idx) = self(gq_idx).GardenSize(1);
                tb.GardenColumns(gq_idx) = self(gq_idx).GardenSize(2);
                tb.TreeDensity(gq_idx) = self(gq_idx).TreeDensity;
                tb.FoliageType(gq_idx) = self(gq_idx).FoliageType;
            end
            return;
        end

        function gardeninfos = get_filtered(self, gqargs)
            %% Retrieve only some gardens, based on criteria.
            arguments
                self (:, 1) lhp.benchmark.GardenQuery = ...
                    lhp.benchmark.GardenQuery.get_all();
                gqargs.?lhp.benchmark.GardenQuery
            end

            filter = true(numel(self), 1);

            if isfield(gqargs, "GardenSize")
                filter = filter & ...
                    all(cat(1, self.GardenSize) == gqargs.GardenSize, 2);
            end
            if isfield(gqargs, "GardenType")
                filter = filter & ...
                    (cat(1, self.GardenType) == gqargs.GardenType);
            end
            if isfield(gqargs, "TreeDensity")
                filter = filter & ...
                    (cat(1, self.TreeDensity) == gqargs.TreeDensity);
            end
            if isfield(gqargs, "FoliageType")
                filter = filter & ...
                    (cat(1, self.FoliageType) == gqargs.FoliageType);
            end

            gardeninfos = self(filter);
            return;
        end

        %% I don't want any bloody setters!!!
%         function self = set.GardenSize(self, ~)
%         end
%
%         function self = set.GardenType(self, ~)
%         end
%
%         function self = set.TreeDensity(self, ~)
%         end
    end

    methods (Static)
        function gardeninfos = get_all()
            files = lhp.benchmark.GardenQuery.raw_files();
            gardeninfos = lhp.benchmark.GardenQuery.empty(1, 0);

            for f_idx = 1:numel(files)
                filename = files(f_idx);
                ret = load(filename);
                fn = fieldnames(ret);

                assert((numel(fn) == 1) && isstruct(ret.(fn{1})), ...
                    "Expected exactly one struct variable in file '%s'!", ...
                    filename);

                gs = ret.(fn{1});
                garden_type = string(subsref(strsplit(fn{1}, "_"), substruct(...
                    '{}', {1})));
                garden_sizes = subsref(cat(1, gs.garden_size), substruct(...
                    '()', {':', ':'}));
                tmp = fieldnames(gs);
                tree_densities = double(arrayfun(@(cell) cell{1}{1}, ...
                    regexpi(string(tmp(2:end)), "td_(\d+)$", "tokens"))) ./ 100;
                foliages = lhp.benchmark.GardenQuery.FOLIAGE_TYPES;

                gi = lhp.benchmark.GardenQuery.empty(...
                    numel(garden_sizes) * numel(tree_densities) * numel(foliages), 0);
                index = 1;
                for gs_idx = 1:size(garden_sizes, 1)
                    for td_idx = 1:numel(tree_densities)
                        for fol_idx = 1:numel(foliages)
                            garden = gs(gs_idx).(sprintf("td_%02d", ...
                                tree_densities(td_idx) * 100));
                            
                            if fol_idx > 1
                                garden = lhp.benchmark.GardenQuery.replace_foliage(...
                                    garden, foliages(fol_idx));
                            end
                            
                            gi(index) = lhp.benchmark.GardenQuery(...
                                garden, ...
                                garden_type, ...
                                garden_sizes(gs_idx, :), ...
                                tree_densities(td_idx), ...
                                foliages(fol_idx));
                            index = index + 1;
                        end
                    end
                end

                gardeninfos = cat(2, gardeninfos, gi);
            end

            gardeninfos = gardeninfos.';
            return;
        end
        
        function G = replace_foliage(garden, pattern)
            blocked = (garden.Raw < 0);

            % Create a new, completely empty garden
            G = lhp.Garden.random(size(garden, 1), size(garden, 2), ...
                "TreeDensity", 0, ...
                "WithShed", false, ...
                "ShedSize", [1, 1], ...
                "WithCompost", false, ...
                "LeavesDistributionType", pattern, ...
                "Export", false);

            % Add the blocked fields from before back in
            G.Raw(blocked) = garden.Raw(blocked);
        end

        function files = raw_files()
            resdir = string(fileparts(mfilename('fullpath'))) + "/+resources";
            dirret = dir(resdir + "/*.mat");
            files = arrayfun(...
                @(filestruct) fullfile(resdir, filestruct.name), dirret);
            return;
        end
    end

end

