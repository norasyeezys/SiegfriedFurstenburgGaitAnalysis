function D = fb_trim_dem(matfile, win)
% FB_TRIM_DEM  Cut the Fuerstenberg out of the Xanten DGM1 and keep it small.
%   D = fb_trim_dem(matfile, [Emin Emax Nmin Nmax])
%
%   Source is ~/dgm1_xanten_merged.tif (ETRS89 / UTM 32N, 1 m bare earth,
%   Geobasis NRW). If the merged file is missing, the 1 km tiles in
%   ~/dgm1_xanten/ are stitched instead. The trimmed block is cached in
%   matfile, so the 1.6 GB raster is only touched once.
%
%   D.Z  heights [m], row index grows NORTH, column index grows EAST
%   D.E  1 x nx cell-centre eastings,  D.N  ny x 1 cell-centre northings
%
%   MATLAB R2012b, no toolboxes (imread + imfinfo only).

if exist(matfile, 'file')
    S = load(matfile);
    D = S.D;
    return;
end

home   = getenv('HOME');
merged = fullfile(home, 'dgm1_xanten_merged.tif');
nx = round(win(2) - win(1));
ny = round(win(4) - win(3));
Z  = [];
src = '';

if exist(merged, 'file')
    info = imfinfo(merged);
    if isfield(info, 'ModelTiepointTag') && ~isempty(info.ModelTiepointTag)
        tp = info.ModelTiepointTag;
        ps = info.ModelPixelScaleTag;
        E0 = tp(4) - tp(1)*ps(1);          % outer west edge of column 1
        N0 = tp(5) + tp(2)*ps(2);          % outer north edge of row 1
        c1 = round((win(1) - E0)/ps(1)) + 1;
        r1 = round((N0 - win(4))/ps(2)) + 1;
        Z  = imread(merged, 'PixelRegion', {[r1, r1+ny-1], [c1, c1+nx-1]});
        src = merged;
    end
end

if isempty(Z)
    % stitch from the 1 km tiles: dgm1_32_<Ekm>_<Nkm>_1_nw_<year>.tif
    Z = nan(ny, nx);
    tdir = fullfile(home, 'dgm1_xanten');
    for ek = floor(win(1)/1000):floor((win(2)-1)/1000)
        for nk = floor(win(3)/1000):floor((win(4)-1)/1000)
            dd = dir(fullfile(tdir, sprintf('dgm1_32_%d_%d_1_nw_*.tif', ek, nk)));
            if isempty(dd), continue; end
            T  = double(imread(fullfile(tdir, dd(1).name)));   % row 1 = north
            te = ek*1000; tn = nk*1000 + 1000;                  % NW corner
            cc = max(win(1), te) : min(win(2), te+1000) - 1;    % west edges
            rr = max(win(3), tn-1000) : min(win(4), tn) - 1;    % south edges
            Z(win(4) - rr, cc - win(1) + 1) = T(tn - rr, cc - te + 1);
        end
    end
    src = tdir;
end

Z = double(Z);
Z(Z < -1000) = NaN;                        % GDAL nodata is -9999
if any(isnan(Z(:)))
    Z(isnan(Z)) = min(Z(~isnan(Z)));
end

D.Z   = single(flipud(Z));                 % row 1 = south from here on
D.E   = win(1) + 0.5 + (0:nx-1);
D.N   = (win(3) + 0.5 + (0:ny-1))';
D.win = win;
D.src = src;
D.crs = 'ETRS89 / UTM zone 32N (EPSG:25832), heights DHHN2016';
save(matfile, 'D');
