/* Ce projet consiste à analyser les ventes, les clients, les produits, les retours, les employés et les paiements
dans une chaîne de magasins en France. Vous allez effectuer des requêtes SQL pour extraire des insights
utiles pour le service marketing et la direction générale.*/

USE retail_db_large;

/* Nombre total de ventes par mois et année */
create or replace view Nombre_total_de_ventes_par_mois_et_année as 
select count(*) as nombre_de_vente, monthname(sale_date) as mois,year(sale_date) as année
 from sales 
group by  année , mois
order by année , mois ;

/* Top 10 des produits les plus vendus (quantité)*/
create or replace view produits_les_plus_vendus as 
select  sales.product_id,  products.name as nom_du_produit, sum(sales.quantity)  as quantité_vendues from products
 inner join Sales on sales.product_id = products.product_id
group by  sales.product_id ,nom_du_produit
order by quantité_vendues DESC
limit 10 offset 0 ;

/* Catégories de produits les plus vendus (quantité)*/
create or replace  view produits_plus_vendus_par_categories as 
select  products.category as catégorie_du_produit, sum(sales.quantity)  as quantité_vendues from products
inner join Sales on sales.product_id = products.product_id
group by  catégorie_du_produit
order by quantité_vendues DESC;

/* Chiffre d'affaires par magasin */
create or replace view chiffre_d_affaires_par_magasin as
select stores.store_id, stores.name as magasin, sum(sales.quantity * products.price) as chiffre_d_affaires  from sales
inner join products on sales.product_id = products.product_id
inner join stores on sales.store_id = stores.store_id
group by stores.store_id, magasin
order by magasin;

/* 7 Meilleurs employés par volume de ventes*/
create or replace view Meilleurs_employes_par_V_ventes as 
select   sales.employee_id, employees.name as nom_des_employés , count(*) as nombre_de_vente
from sales 
inner join employees on employees.employee_id = sales.employee_id
group by  nom_des_employés ,  employee_id
order by nombre_de_vente DESC
LIMIT 7;

/* Nombre de clients par tranche d'âge */
create or replace view nombre_de_clients_par_tranche_d_age as 
Select distinct  count(*) as nombre_de_clients,  
case 
  when timestampdiff(year , birth_date ,curdate()) between 0 and 25 then '0-25ans'
  when timestampdiff(year , birth_date ,curdate()) BETWEEN 26 and 50 then '26-50ans'
  when timestampdiff(year , birth_date ,curdate()) between 51 and 75 then '51-75ans'
  else  'trosieme age'
  end as groupe_age from customers
  group by groupe_age  ;
  
/* Taux de retour global des ventes */
create or replace  view Taux_de_retour_global_de_ventes as 
select (count(distinct returns.sale_id) * 100 / count(distinct sales.sale_id)) as taux_de_retour_global from returns
right join Sales on returns.sale_id = sales.sale_id;

/*  Évolution du chiffre d'affaires mensuel */
create or replace view Evolution_CA_mensuel as 
select   monthname(sale_date) as mois, year(sale_date) as année,  sum(sales.quantity * products.price) as chiffre_d_affaires  from sales
inner join products on sales.product_id = products.product_id
group by année , mois ,month(sale_date)
order by année, month(sale_date);

/* Produits les mieux notés par les clients */
create or replace  view produits_les_mieux_notés_par_clients as
select reviews.product_id , products.name as produit_les_mieux_notés , reviews.rating as note from reviews
inner join Products on products.product_id = reviews.product_id
where reviews.rating = 5 ;

/* Paiements par mode de paiement */
create or replace view paiements_par_mode_de_paiements as 
select count(*)  as nombre_de_payements , payment_method from payments
group by payment_method;

/* Impact des promotions sur les ventes
Vente totale par produit pendant les promotions */
create or replace view ventes_produits_promotions as 
select product_id, prix_promotion, sum(prix_promotion * quantity) as prix_promo_par_produit , start_date, end_date from (
select promotions.product_id , (products.price * promotions.discount_percentage / 100 ) as reduction , 
(products.price-(products.price * promotions.discount_percentage / 100 )) as prix_promotion, promotions.start_date,
promotions.end_date , sales.quantity  from promotions
inner join products on products.product_id = promotions.product_id
inner join Sales on sales.product_id = promotions.product_id
where ( sales.sale_date) between promotions.start_date and promotions.end_date 
order by product_id ) as prix_total_promo
group by product_id , prix_promotion , start_date, end_date
order by prix_promo_par_produit DESC; 

/* Vente totale hors promotion par produit*/ 
create or replace view vente_totale_des_produits_hors_promotion as 
select product_id , sum(price*quantity) as prix_sans_promo from (
select distinct sale_date , product_id, quantity ,price from (
select distinct sales.sale_date, sales.product_id,  promotions.start_date, promotions.end_date
, products.price, sales.quantity from promotions
inner join products on products.product_id = promotions.product_id
inner join Sales on sales.product_id = promotions.product_id
where ( sales.sale_date) not between promotions.start_date and promotions.end_date 
group by products.product_id, sales.sale_date ,sales.product_id , promotions.start_date,promotions.end_date,
products.price , sales.quantity 
order by product_id) as vente_hors_promo ) as vente_hors_promotion
group by product_id;
