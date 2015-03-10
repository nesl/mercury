classdef MapManager < handle
    properties (SetAccess = public, GetAccess = public)
        info = {
            % 15       24                       49       58       67       76       85       94       103:cursor location
            % Map_ID   City name                Size 1,  Size 2,  Size 3,  Size 4,  Size 5,  Size 6,  Size 7
              1,       'Albuquerque',           [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              2,       'Atlanta',               [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              3,       'Austin',                [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              4,       'Baltimore',             [],      [],      [],      [],      [],      [],      []       
              5,       'Boston',                [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              6,       'Charlotte',             [],      [],      [],      [],      [],      [],      []       
              7,       'Chicago',               [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              8,       'Cleveland',             [],      [],      [],      [],      [],      [],      []       
              9,       'Columbus',              [],      [],      [],      [],      [],      [],      []       
              10,      'Dallas',                [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              11,      'Denver',                [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              12,      'Detroit',               [],      [],      [],      [],      [],      [],      []       
              13,      'El_Paso',               [],      [],      [],      [],      [],      [],      []       
              14,      'Fort_Worth',            [],      [],      [],      [],      [],      [],      []       
              15,      'Fresno',                [],      [],      [],      [],      [],      [],      []       
              16,      'Houston',               [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              17,      'Indianapolis',          [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              18,      'Jacksonville',          [],      [],      [],      [],      [],      [],      []       
              19,      'Kansas_City_2',         [],      [],      [],      [],      [],      [],      []       
              20,      'Kansas_City',           [],      [],      [],      [],      [],      [],      []       
              21,      'Las_Vegas',             [],      [],      [],      [],      [],      [],      []       
              22,      'Long_Beach',            [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              23,      'Los_Angeles',           [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              24,      'Memphis',               [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              25,      'Mesa',                  [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              26,      'Milwaukee',             [],      [],      [],      [],      [],      [],      []       
              27,      'Nashville',             [],      [],      [],      [],      [],      [],      []       
              28,      'New_Orleans',           [],      [],      [],      [],      [],      [],      []       
              29,      'New_York',              [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              30,      'Oklahoma_City',         [],      [],      [],      [],      [],      [],      []       
              31,      'Omaha',                 [],      [],      [],      [],      [],      [],      []       
              32,      'Philadelphia',          [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              33,      'Phoneix',               [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              34,      'Portland',              [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              35,      'Sacramento',            [],      [],      [],      [],      [],      [],      []       
              36,      'San_Antonio',           [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              37,      'San_Diego',             [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              38,      'San_Francisco',         [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              39,      'San_Jose',              [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              40,      'San_Juan',              [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              41,      'Seattle',               [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              42,      'Tucson',                [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              43,      'Virginia_Beach',        [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              44,      'Washington',            [],      '2x2',   '3x3',   '4x4',   '5x5',   '6x6',   []       
              % university
              101,     'ucla',                  'west',  'small', '3x3',   '4x4',   '5x5',   [],      []       
              % feel free to add more. The Map_ID doesn't need to be continuous.
        };
    
        folder = '';
    end
    
    methods
        function obj = MapManager(varargin)
            if length(varargin) == 1
                obj.folder = varargin{1};
            end
        end
        
        function [mapDataObj, mapPath] = getMapDataObject(obj, mapID, mapSize, downSampleSize)
            for i = 1:size(obj.info, 1)
                if obj.info{i, 1} == mapID
                    if numel(obj.info{i, mapSize+2}) == 0
                        error('Find the map, yet cannot find the corresponding size');
                    end
                    mapPath = strcat(obj.folder, obj.info{i, 2}, '_', obj.info{i, mapSize+2}, '.map');
                    mapDataObj = MapData(mapPath, downSampleSize);
                    return
                end
            end
            error('The specified map_ID is not existed');
        end
        
        function mapID = getMapIPByName(obj, cityName)
            % TODO
        end
        
        function idx = getMapIdx(obj, id)
            idx = -1;
            for i=1:size(obj.info,1)
                if obj.info{i,1} == id
                    idx = i;
                    return;
                end
            end
        end
        
        function name = getMapFile(obj, id, sz)
            idx = obj.getMapIdx(id);
            name = strcat(obj.folder, obj.info{idx, 2}, '_', obj.info{idx, sz+2}, '.map');
        end
        
        function name = getMapName(obj, id, sz)
            idx = obj.getMapIdx(id);
            name = strcat(obj.info{idx, 2}, '_', obj.info{idx, sz+2});
        end
        
        function maps = getValidMaps(obj, sz)
            maps = {};
            for i=1:size(obj.info,1)
                if ~isempty(obj.info{i,2+sz})
                    fpath = strcat(obj.folder, obj.info{i,2}, '_', obj.info{i,2+sz}, '.map');
                    maps = [maps; fpath];
                end
            end
        end
        
        function ids = getValidMapIds(obj, sz)
            ids = [];
            for i=1:size(obj.info,1)
                if ~isempty(obj.info{i,2+sz})
                    ids = [ids; obj.info{i,1}];
                end
            end
        end
        
    end
    
end

