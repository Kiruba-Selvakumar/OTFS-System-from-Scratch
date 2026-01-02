function pre_OTFS_tx(num_bits, modulation_order, delay_max, doppler_max, M, N, gtx_t, N_cp)

    %  Generate raw data using random number generator (suppose 1e3 bits)
    rawbits = randi([0 1], num_bits, 1); % Random bits

    % Modulation (I'm plotting the constellation here for verification)
    switch modulation_order
        case 2 % BPSK
            rawsymbols = pskmod(rawbits, 2, 'InputType', 'bit', 'PlotConstellation', true);
        case 4 % QPSK
            rawsymbols = pskmod(rawbits, 4, pi/4, 'InputType', 'bit', 'PlotConstellation', true);
        otherwise
            rawsymbols = qammod(rawbits, modulation_order, 'UnitAveragePower', true, 'InputType', 'bit', 'PlotConstellation', true);
    end

    % Split symbols into blocks suitable for OTFS and call OTFS_tx for each block
    num_data_symbols_per_block = M * N - (2 * delay_max + 1) * (2 * doppler_max + 1); % Total symbols minus pilot and guard bands
    num_blocks = ceil(length(rawsymbols) / num_data_symbols_per_block); 

    for ix = 1:num_blocks
        start_idx = (ix-1) * num_data_symbols_per_block + 1;
        end_idx = min(ix * num_data_symbols_per_block, length(rawsymbols));
        symbol_block = rawsymbols(start_idx:end_idx);

        % If the last block is shorter, pad with zeros
        if length(symbol_block) < num_data_symbols_per_block
            symbol_block = [symbol_block; zeros(num_data_symbols_per_block - length(symbol_block), 1)];
        end

        % Call OTFS_tx for each block
        txsignal_blocks{ix} = OTFS_tx(symbol_block, delay_max, doppler_max, M, N, gtx_t, N_cp);
    end
end

function cp_txsignal_t = OTFS_tx(symbolstream, delay_max, doppler_max, M, N, gtx_t, N_cp)

    % I've ensured symbols is a vector of appropriate size that fits into the DD grid with pilot and guard bands

    ddgrid = zeros(M, N); % Initialize Delay Doppler grid
    
    % Introduce pilot at center of the grid
    delaycenter_idx = floor(M/2) + rem(M,2);
    dopplercenter_idx = floor(N/2) + rem(N,2);
    ddgrid(delaycenter_idx, dopplercenter_idx) = 1;

    % Surround pilot symbol with guard band of zeros (they've been set to zero already)

    % Map raw symbols to Delay Doppler grid (excluding pilot and guard band)
    idx = 1;
    for m = 1:M
        for n = 1:N
            % Check if the current position is outside the guard band around the pilot
            if ~((m >= delaycenter_idx-delay_max && m <= delaycenter_idx+delay_max) && (n >= dopplercenter_idx-doppler_max && n <= dopplercenter_idx+doppler_max))
                ddgrid(m,n) = symbolstream(idx);
                idx = idx + 1;
            end
        end
    end

    % Delay Doppler grid to Delay Time grid (M delays and N Dopplers) 
    dtgrid = ifft(ddgrid,[],2) * sqrt(size(ddgrid,2)); % IFFT along Doppler (along a row) (use the sqrt(N) definition)

    % Pulse shaping in Delay Time domain; multiply each column with gtx_t
    pulseShaped_dtgrid = gtx_t .* dtgrid;

    % Vectorisation of the Pulse shaped Delay Time grid. Columns stacked below each other
    txsignal_t = reshape(pulseShaped_dtgrid, [], 1);

    % Add CP to the signal 
    cp_txsignal_t = [txsignal_t(end-N_cp+1:end); txsignal_t]; % Add CP of length N_cp
end

