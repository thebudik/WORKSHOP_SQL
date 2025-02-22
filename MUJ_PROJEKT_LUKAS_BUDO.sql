
--- Bod č.1 Historie půjček
select
    extract(YEAR from date) as pujcky_rok,
    extract(QUARTER from date) as pujcky_ctvrtleti,
    extract(MONTH from date) as pujcky_mesic,
    sum(amount) as vyse_pujcek,
    avg(amount) as prumer_pujcek,
    count(loan_id) as pocet_pujcek
from loan
group by pujcky_rok,
         pujcky_ctvrtleti,
         pujcky_mesic
with rollup;

--- Bod č.2 - Stav půjčky
select
    count(loan_id),
    status
from loan
group by status
order by status;

--- Bod č.3 - Analýza účtů

with anal_acc as (
    select
        account_id,
        amount
    from loan
    where status IN ('A', 'C')
)

select
    account_id,
    COUNT(*) AS pocet_pujcek,
    SUM(amount) AS vyse_pujcek,
    AVG(amount) AS prumer_pujcek
from anal_acc
group by account_id
order by
    pocet_pujcek desc,
    vyse_pujcek desc,
    prumer_pujcek;

--- Bod č.4 - Analýza účtů


select
    c.gender as pohlavi,
    SUM(l.amount) as celkova_vyse_splacenych_pujcek
from loan l
join disp d on l.account_id = d.account_id
join  client c on d.client_id = c.client_id
where l.status in ('A', 'C')
group by c.gender;


--- Bod č.5 - Analýza klientů - část 1



create temporary table temp_splacene_pujcky as
select
    d.client_id,
    c.birth_date,
    c.gender,
    l.loan_id,
    l.amount,
    2024 - extract(year from c.birth_date) as vek
from loan l
join disp d on l.account_id = d.account_id
join client c on d.client_id = c.client_id
where l.status IN ('A', 'C');

--- počet splacených půjček dle pohlaví

select
    gender as pohlavi,
    count(loan_id) as celkovy_pocet_splacenych_pujcek
from temp_splacene_pujcky
group by pohlavi
order by celkovy_pocet_splacenych_pujcek desc;

--- průměrný věk dle pohlaví

select
    gender as pohlavi,
    avg(vek) as prumerny_vek
from temp_splacene_pujcky
group by pohlavi
order by prumerny_vek desc;

drop table if exists temp_splacene_pujcky

--- Bod č.6 - Analýza klentů část 2


drop table if exists temp_mistni_analyza

create temporary table temp_mistni_analyza as
    select
        c.district_id,
        count(distinct dp.client_id) as pocet_klientu,
        sum(l.amount) as vyse_pujcek,
        count(l.amount) as pocet_pujcek
    from loan l
    join account a on a.account_id = l.account_id
    join disp dp on dp.account_id = l.account_id
    join client c on c.client_id = dp.client_id
    join district d on c.district_id = d.district_id
    where dp.type = 'OWNER'
    and l.status in ('A', 'C')
    group by c.district_id;

select *
from temp_mistni_analyza
order by pocet_klientu desc
limit 1;

select *
from temp_mistni_analyza
order by vyse_pujcek desc
limit 1;

select *
from temp_mistni_analyza
order by pocet_pujcek desc
limit 1;



--- Bod č. 7 - analýza klientů - část 3

set  @celkova_vyse_pujcek = (select sum(temp_mistni_analyza.vyse_pujcek) from temp_mistni_analyza);

select
    t.district_id,
    t.pocet_klientu,
    t.pocet_pujcek,
    t.vyse_pujcek,
    t.vyse_pujcek / @celkova_vyse_pujcek as podil_vyjpucek
from temp_mistni_analyza t
order by podil_vyjpucek desc
limit 2;


--- Bod č. 8 - část - výběr klienta

with klienti_s_pujckou as (
    select
        c.client_id,
        c.birth_date,
        count(l.loan_id) as pocet_pujcek,
        sum(l.amount) - coalesce(sum(l. payments),0) as zustatek_na_uctu
    from client c
    join disp dp on dp.client_id = c.client_id
    join account a on a.account_id = dp.account_id
    join loan l on l.account_id = a.account_id
    where dp.type = 'OWNER'
        and l.status in ('A', 'C')
    group by c.client_id, c.birth_date
)

select
    k.client_id,
    k.birth_date,
    k.pocet_pujcek,
    k.zustatek_na_uctu
from klienti_s_pujckou k
where k.zustatek_na_uctu > 1000
    and k.pocet_pujcek > 5
    and extract(year from k.birth_date) > 1990
order by zustatek_na_uctu desc;

--- Bod č. 9 - část - výběr klienta část 2

with klienti_s_pujckou as (
    select
        c.client_id,
        c.birth_date,
        count(l.loan_id) as pocet_pujcek,
        sum(l.amount) - coalesce(sum(l. payments),0) as zustatek_na_uctu
    from client c
    join disp dp on dp.client_id = c.client_id
    join account a on a.account_id = dp.account_id
    join loan l on l.account_id = a.account_id
    where dp.type = 'OWNER'
        and l.status in ('A', 'C')
    group by c.client_id, c.birth_date
)

select
    k.pocet_pujcek,
    k.birth_date,
    k.zustatek_na_uctu
from klienti_s_pujckou k
order by zustatek_na_uctu desc;


select birth_date
from client
where extract(year from birth_date) > 1990;


select
    c.client_id,
    count(l.loan_id) as pocet_pujcek
from client c
join disp dp on dp.client_id = c.client_id
join account a on a.account_id = dp.account_id
join loan l on l.account_id = a.account_id
group by c.client_id
having pocet_pujcek > 1;


select
    c.client_id,
    sum(l.amount) - coalesce(sum(l.payments),0) as zustatek_na_uctu,
from client c
join disp dp on dp.client_id = c.client_id
join account a on a.account_id = dp.account_id
join loan l on l.account_id = a.account_id
group by c.client_id
order by zustatek_na_uctu asc;

--- Bod č. 10 - část - výběr klienta část 2

create table if not exists cards_at_expiration (
    client_id int not null,
    card_id int not null,
    expiration date null,
    client_adress varchar(255) not null,
    generated_for_date date null
);

DELIMITER $$

drop procedure if exists generovani_kart_s_expiraci $$

create procedure generovani_kart_s_expiraci(in p_date DATE)

begin
    if p_date is null then
        set p_date = curdate();
    end if;

insert into cards_at_expiration
    with cte as (
        select
            dp.client_id,
            c.card_id,
            date_add(c.issued, interval 3 year) as datum_expirace,
            cl.district_id as adresa_klienta
        from card c
        join disp dp on dp.disp_id = c.disp_id
        join client cl on cl.client_id = dp.client_id
        join district d on d.district_id = cl.district_id
        )

select *,
       p_date
from cte
where p_date between date_sub(datum_expirace, interval 7 day) and datum_expirace;
end $$

delimiter;


call generovani_kart_s_expiraci('2020-01-01')

select *
from cards_at_expiration;




