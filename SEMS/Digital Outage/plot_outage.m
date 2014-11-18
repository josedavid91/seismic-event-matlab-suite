function plot_outage(M)

D = M.Outage;
subnets = fieldnames(D);
dat = [];
names = {};

for n = 1:numel(subnets)
    SU = subnets{n};
    stations = fieldnames(D.(SU));
    for m = 1:numel(stations)
        ST = stations{m};
        dat = [dat, D.(SU).(ST).BHZ];
        names{end + 1} = [SU,':',ST];
    end
end
imagesc(M.TimeVector,1:length(names),dat')
set(gca,'YDir','normal')
set(gcf,'Color','w')
Cmap = [linspace(1,0,64)', linspace(1,0,64)', linspace(1,.5,64)'];
colormap(Cmap);
dynamicDateTicks
grid on
set(gca,'YTick',1:length(names))
set(gca,'YTickLabel',names(end:-1:1))