create schema stg;

CREATE TABLE stg.samplekafka2postgres (
	dttm timestamptz NULL,
	txt text NULL
);


create schema ods;

CREATE TABLE ods.samplekafka2postgres (
	id serial4 NOT NULL,
	ins_dttm timestamptz default now() NOT NULL,
	dttm timestamptz NULL,
	txt text NULL,
	CONSTRAINT samplekafka2postgres_pkey PRIMARY KEY (id)
);

create or replace procedure ods.load_samplekafka2postgres()
language plpgsql 
as $$
begin 
	-- перенос содержимого таблицы в ods полностью
	insert into ods.samplekafka2postgres(dttm, txt)
	select dttm, txt
	from stg.samplekafka2postgres;

	-- удаление делаем в процессе NiFi
	-- delete from stg.samplekafka2postgres;

	commit;
end; $$;

-- Примеры запросов
select * from ods.samplekafka2postgres;

delete from stg.samplekafka2postgres;
delete from ods.samplekafka2postgres where ins_dttm < now() - interval '10 minute'; 

select * from stg.samplekafka2postgres;
select * from ods.samplekafka2postgres order by id desc;
select count(*) from ods.samplekafka2postgres;
