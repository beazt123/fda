Conf = config;
PATH_TO_IDG_TRANSFORMED_DATA = Conf.PATH_TO_IDG_TRANSFORMED_DATA;
run("dataPreprocessor1.m");
generateFlightDataMasterList(PATH_TO_IDG_TRANSFORMED_DATA,1);
run("dataPreprocessor2.m");
load("gong.mat");sound(y)