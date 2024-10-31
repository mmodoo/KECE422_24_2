clc
clear all
close all

Fs = 2000;
recording_time_sec = 50;

img_path = 'C:\Users\Donghwi\Desktop\DoHW\24-2\통설\Report4';

% Source Encoding
imresize_scale = 0.5;
img = imread(fullfile(img_path, 'Lena_color.png'));
resized_img = imresize(img, imresize_scale);
gray_img = rgb2gray(resized_img);
binarized_img = imbinarize(gray_img);
bits = binarized_img(:);
repetition_factor = 3;
channel_coded_bits = repelem(bits, repetition_factor);

% Modulation & Parameter setting
symbols = 2 * channel_coded_bits - 1;

M = length(symbols);
N = 256;
N_cp = 128;
cn = M / (N / 2);
N_blk = cn + cn / 4;

% Preamble
omega = 10;
mu = 0.1;
Tp = 1000;
tp = (1:Tp).';
preamble = cos(omega * tp + mu * tp.^2 / 2);

% 수신 시작
devicereader = audioDeviceReader(Fs);
setup(devicereader);
disp('Recording...')
rx_signal = [];
tic;
while toc < recording_time_sec  % 10초 동안 녹음
    acquiredAudio = devicereader();
    rx_signal = [rx_signal; acquiredAudio];
end

disp('Recording Completed')

% Time Synchronisation
[xC, lags] = xcorr(rx_signal, preamble);
[~, idx] = max(xC);
start_pt = lags(idx);

rx_signal = rx_signal(start_pt + Tp + 1 : end);

% Serial to Parallel
OFDM_blks = {};
for i = 1 : N_blk
    OFDM_blks{end + 1} = rx_signal(N_cp + 1 : N + N_cp);
    rx_signal = rx_signal(N_cp + N + 1 : end);
end

% Discrete Fourier Transform (DFT)
demode_OFDM_blks = {};
for i = 1 : length(OFDM_blks)
    demode_OFDM_blks{end + 1} = fft(OFDM_blks{i} / sqrt(N));
end

% Channel Estimation & Equalisation
symbols_eq = {};
for i = 1 : length(demode_OFDM_blks)
    if rem(i, 5) == 1
        channel = demode_OFDM_blks{i} ./ ones(N, 1);
    else
        symbols_eq{end + 1} = demode_OFDM_blks{i} ./ channel;
    end
end

% Detection
symbols_detect = {};
for i = 1 : length(symbols_eq)
    symbols_detect{end + 1} = sign(real(symbols_eq{i}));
end

% Demodulation
symbols_est = [];
for i = 1 : length(symbols_detect)
    symbols_est = [symbols_est; symbols_detect{i}(2 : N / 2 + 1)];
end

decoded_bits = (symbols_est + 1) / 2;
decoded_bits_reshaped = reshape(decoded_bits, 3, []);

% Determine bits
sums = sum(decoded_bits_reshaped);
repetition_decoded_bits = (sums >= 2).';



% Source Decoding & Show img
estimated_img = reshape(decoded_bits, [sqrt(length(decoded_bits)), sqrt(length(decoded_bits))]); 
resized_estimated_img = imresize(estimated_img, 1 / imresize_scale);
imshow(resized_estimated_img);

disp('Communication Tool box에 있는 biterr 함수를 사용하여 Bit Error Rate를 구합니다.');
[~, BER_repetition_uncoded] = biterr(bits, repetition_decoded_bits);
disp(BER_repetition_uncoded);

