% Parameter setting
% sampling frequency
sampling_freq = 10000;
% N, that is #sub-carrier
N = 256;
% cyclic prefix len
N_cp = N / 4;
% preamble len
Tp = 1000;
% 이미지 경로
img_path = 'C:\Users\Donghwi\Desktop\DoHW\24-2\통설\Report4';

clc;
close all;

% disp('############### Step 3. 이미지 전송에 repetition coding을 적용해 보겠습니다.');
disp('################################### tx_signal을 만들겠습니다.');

% disp('image를 읽어옵니다.');
img = imread(fullfile(img_path, 'Lena_color.png'));

% disp('image를 factor 비율만큼 줄입니다.');
img_resize_scale_rate = 0.5;
resized_img = imresize(img, img_resize_scale_rate);

% disp('image를 gray-scale로 바꿉니다.');
gray_img = rgb2gray(resized_img);

% disp('image를 monochrome으로 바꿉니다.');
binarised_img = imbinarize(gray_img);

% disp('bit로 전송하기 위해, Column vector로 형식을 바꿉니다.');
bits = binarised_img(:);

% disp('repetition coding을 적용합니다. 반복 횟수는 3회입니다.');
repetition_factor = 3;
channel_coded_bits = repelem(bits, repetition_factor);

% disp('BPSK modulation을 합니다.');
symbols = 2 * channel_coded_bits - 1;

% disp('symbol len, 전체 OFDM 심볼의 개수, pilot 신호를 포함한 전체 블록의 개수를 설정합니다.');
M = length(symbols);
cn = M / (N / 2);
N_blk = cn + cn / 4;

% disp('Block별로 Serial 신호를 싣기 위해 Parallel로 바꿉니다.');
symbols_freq = {};
for i = 1:cn
    symbols_freq{end + 1} = [0; symbols(N/2*(i-1)+1 : N/2*i)];
    symbols_freq{end} = [symbols_freq{end}; flip(symbols_freq{end}(2 : end-1))];
end

% disp('Inverse Discrete Fourier Transform을 합니다.')
symbols_time = {};
for i = 1:length(symbols_freq)
    symbols_time{end + 1} = ifft(symbols_freq{i}, N) * sqrt(N);
end

% disp('cyclic prefix를 집어넣습니다.');
for i = 1 : length(symbols_time)
    symbols_time{i} = [symbols_time{i}(end - N_cp + 1 : end); symbols_time{i}];
end

% disp('Pilot signal을 집어넣습니다.');
pilot_freq = ones(N, 1);
pilot_time = ifft(pilot_freq) * sqrt(N);
pilot_time = [pilot_time(end - N_cp + 1 : end); pilot_time];

% disp('Preamble을 설정합니다. ** preamble 길이는 맨 위에서 Tp로 이미 설정하였습니다.');
omega = 10;
mu = 0.1;
tp = (1:Tp).';
preamble = cos(omega * tp + mu * tp.^2 / 2);

% disp('전송하려면 serial이어야 하기 때문에 serial로 바꿉니다.');

tx_signal = [preamble; pilot_time];
for i = 1 : length(symbols_time)
    tx_signal = [tx_signal; symbols_time{i}];
    if rem(i, 4) == 0 && i ~= length(symbols_time)
        tx_signal = [tx_signal; pilot_time];
    end
end

disp("############Tx가 준비되었습니다.########################");

disp('################################### 만들어져 있는 tx_signal을 보내겠습니다.####################');

% audioplayer 객체 생성
player = audioplayer(tx_signal, sampling_freq);    
% 사운드 재생 시작
start_time = datetime("now", "Format", "yyyy-MM-dd HH:mm:ss");
disp(['tx 시작 시각: ', char(start_time)]);
play(player);

% 재생이 끝날 때까지 대기
disp('재생 중입니다.');
while isplaying(player)
    pause(0.5);  % X초 대기 후 재생 상태 다시 체크
    fprintf('.');
end
end_time = datetime("now", "Format", "yyyy-MM-dd HH:mm:ss");
disp('.');
disp(['tx 종료 시각: ', char(end_time)]);
elapsed_time = end_time - start_time;
disp(['tx 중 총 경과 시간[s]: ', char(elapsed_time)]);